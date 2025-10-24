
(define-fungible-token fact-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-stake (err u103))
(define-constant err-invalid-vote (err u104))
(define-constant err-claim-expired (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-not-authorized (err u107))
(define-constant err-insufficient-balance (err u108))

(define-constant min-stake u1000)
(define-constant voting-period u1440)
(define-constant arbitration-period u2880)
(define-constant base-reward u100)

(define-data-var next-claim-id uint u1)
(define-data-var next-dispute-id uint u1)
(define-data-var total-claims uint u0)
(define-data-var treasury-balance uint u0)

(define-map claims
  { claim-id: uint }
  {
    submitter: principal,
    content-hash: (buff 32),
    claim-text: (string-ascii 256),
    status: (string-ascii 20),
    stake-amount: uint,
    created-at: uint,
    votes-for: uint,
    votes-against: uint,
    weighted-votes-for: uint,
    weighted-votes-against: uint,
    total-voters: uint,
    resolved-at: (optional uint)
  }
)

(define-map user-reputation
  { user: principal }
  { score: uint, total-votes: uint, accurate-votes: uint }
)

(define-map claim-votes
  { claim-id: uint, voter: principal }
  { vote: bool, stake: uint, timestamp: uint }
)

(define-map disputes
  { dispute-id: uint }
  {
    claim-id: uint,
    challenger: principal,
    challenger-stake: uint,
    status: (string-ascii 20),
    created-at: uint,
    arbitrator: (optional principal),
    resolution: (optional bool)
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? fact-token u1000000 contract-owner))
    (var-set treasury-balance u500000)
    (ok true)
  )
)

(define-public (submit-claim (content-hash (buff 32)) (claim-text (string-ascii 256)))
  (let
    (
      (claim-id (var-get next-claim-id))
      (current-height stacks-block-height)
    )
    (asserts! (>= (get-balance tx-sender) min-stake) err-insufficient-balance)
    (try! (ft-transfer? fact-token min-stake tx-sender (as-contract tx-sender)))
    (map-set claims
      { claim-id: claim-id }
      {
        submitter: tx-sender,
        content-hash: content-hash,
        claim-text: claim-text,
        status: "pending",
        stake-amount: min-stake,
        created-at: current-height,
        votes-for: u0,
        votes-against: u0,
        weighted-votes-for: u0,
        weighted-votes-against: u0,
        total-voters: u0,
        resolved-at: none
      }
    )
    (var-set next-claim-id (+ claim-id u1))
    (var-set total-claims (+ (var-get total-claims) u1))
    (ok claim-id)
  )
)

(define-public (vote-on-claim (claim-id uint) (support bool) (stake-amount uint))
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) err-not-found))
      (current-height stacks-block-height)
      (voting-deadline (+ (get created-at claim) voting-period))
      (voter-rep (get-user-reputation tx-sender))
      (weighted-amount (calculate-weighted-vote stake-amount (get score voter-rep)))
    )
    (asserts! (< current-height voting-deadline) err-claim-expired)
    (asserts! (>= stake-amount u10) err-insufficient-stake)
    (asserts! (>= (get-balance tx-sender) stake-amount) err-insufficient-balance)
    (asserts! (is-none (map-get? claim-votes { claim-id: claim-id, voter: tx-sender })) err-already-voted)
    (asserts! (is-eq (get status claim) "pending") err-invalid-vote)
    
    (try! (ft-transfer? fact-token stake-amount tx-sender (as-contract tx-sender)))
    
    (map-set claim-votes
      { claim-id: claim-id, voter: tx-sender }
      { vote: support, stake: stake-amount, timestamp: current-height }
    )
    
    (map-set claims
      { claim-id: claim-id }
      (merge claim {
        votes-for: (if support (+ (get votes-for claim) stake-amount) (get votes-for claim)),
        votes-against: (if support (get votes-against claim) (+ (get votes-against claim) stake-amount)),
        weighted-votes-for: (if support (+ (get weighted-votes-for claim) weighted-amount) (get weighted-votes-for claim)),
        weighted-votes-against: (if support (get weighted-votes-against claim) (+ (get weighted-votes-against claim) weighted-amount)),
        total-voters: (+ (get total-voters claim) u1)
      })
    )
    
    (ok true)
  )
)

(define-public (resolve-claim (claim-id uint))
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) err-not-found))
      (current-height stacks-block-height)
      (voting-deadline (+ (get created-at claim) voting-period))
      (votes-for (get votes-for claim))
      (votes-against (get votes-against claim))
      (weighted-for (get weighted-votes-for claim))
      (weighted-against (get weighted-votes-against claim))
      (is-approved (> weighted-for weighted-against))
    )
    (asserts! (>= current-height voting-deadline) err-invalid-vote)
    (asserts! (is-eq (get status claim) "pending") err-invalid-vote)
    
    (begin
      (map-set claims
        { claim-id: claim-id }
        (merge claim {
          status: (if is-approved "approved" "rejected"),
          resolved-at: (some current-height)
        })
      )
      
      (if is-approved
        (begin
          (try! (as-contract (ft-transfer? fact-token base-reward tx-sender (get submitter claim))))
          (unwrap-panic (update-reputation (get submitter claim) true))
        )
        (unwrap-panic (update-reputation (get submitter claim) false))
      )
      
      (unwrap-panic (distribute-rewards claim-id))
      (ok is-approved)
    )
  )
)

(define-public (create-dispute (claim-id uint) (challenger-stake uint))
  (let
    (
      (claim (unwrap! (map-get? claims { claim-id: claim-id }) err-not-found))
      (dispute-id (var-get next-dispute-id))
      (current-height stacks-block-height)
    )
    (asserts! (is-some (get resolved-at claim)) err-invalid-vote)
    (asserts! (>= challenger-stake (* min-stake u2)) err-insufficient-stake)
    (asserts! (>= (get-balance tx-sender) challenger-stake) err-insufficient-balance)
    
    (try! (ft-transfer? fact-token challenger-stake tx-sender (as-contract tx-sender)))
    
    (map-set disputes
      { dispute-id: dispute-id }
      {
        claim-id: claim-id,
        challenger: tx-sender,
        challenger-stake: challenger-stake,
        status: "pending",
        created-at: current-height,
        arbitrator: none,
        resolution: none
      }
    )
    
    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

(define-public (arbitrate-dispute (dispute-id uint) (resolution bool))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-not-found))
      (current-height stacks-block-height)
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status dispute) "pending") err-invalid-vote)
    
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: "resolved",
        arbitrator: (some tx-sender),
        resolution: (some resolution)
      })
    )
    
    (begin
      (if resolution
        (try! (as-contract (ft-transfer? fact-token (get challenger-stake dispute) tx-sender (get challenger dispute))))
        (begin
          (try! (as-contract (ft-transfer? fact-token (/ (get challenger-stake dispute) u2) tx-sender contract-owner)))
          (unwrap-panic (update-reputation (get challenger dispute) false))
        )
      )
    )
    
    (ok resolution)
  )
)

(define-public (mint-tokens (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? fact-token amount recipient))
    (ok true)
  )
)

(define-public (transfer-tokens (recipient principal) (amount uint))
  (begin
    (asserts! (>= (get-balance tx-sender) amount) err-insufficient-balance)
    (try! (ft-transfer? fact-token amount tx-sender recipient))
    (ok true)
  )
)

(define-read-only (get-claim (claim-id uint))
  (map-get? claims { claim-id: claim-id })
)

(define-read-only (get-user-reputation (user principal))
  (default-to { score: u0, total-votes: u0, accurate-votes: u0 }
    (map-get? user-reputation { user: user })
  )
)

(define-read-only (get-balance (user principal))
  (ft-get-balance fact-token user)
)

(define-read-only (get-vote (claim-id uint) (voter principal))
  (map-get? claim-votes { claim-id: claim-id, voter: voter })
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? disputes { dispute-id: dispute-id })
)

(define-read-only (get-total-claims)
  (var-get total-claims)
)

(define-read-only (get-treasury-balance)
  (var-get treasury-balance)
)

(define-read-only (calculate-weighted-vote (stake-amount uint) (reputation-score uint))
  (let
    (
      (base-multiplier u100)
      (reputation-multiplier (if (> reputation-score u0) (+ u100 reputation-score) u100))
      (weighted-stake (/ (* stake-amount reputation-multiplier) base-multiplier))
    )
    weighted-stake
  )
)

(define-private (update-reputation (user principal) (accurate bool))
  (let
    (
      (current-rep (get-user-reputation user))
      (new-total (+ (get total-votes current-rep) u1))
      (new-accurate (if accurate (+ (get accurate-votes current-rep) u1) (get accurate-votes current-rep)))
      (new-score (/ (* new-accurate u100) new-total))
    )
    (map-set user-reputation
      { user: user }
      {
        score: new-score,
        total-votes: new-total,
        accurate-votes: new-accurate
      }
    )
    (ok true)
  )
)

(define-private (distribute-rewards (claim-id uint))
  (let
    (
      (claim (unwrap-panic (map-get? claims { claim-id: claim-id })))
      (total-stake (+ (get votes-for claim) (get votes-against claim)))
      (winning-stake (if (> (get votes-for claim) (get votes-against claim)) (get votes-for claim) (get votes-against claim)))
      (reward-pool (* total-stake u1))
    )
    (if (> winning-stake u0)
      (var-set treasury-balance (- (var-get treasury-balance) reward-pool))
      true
    )
    (ok true)
  )
)

