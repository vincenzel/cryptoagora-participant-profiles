;; CryptoAgora - Community Profile Management Network

;; ===============
;; Storage Systems
;; ===============

;; Core participant registry storage
(define-map participant-registry
  { participant-id: uint }
  {
    display-handle: (string-ascii 50),
    crypto-address: principal,
    onboarding-timestamp: uint,
    personal-description: (string-ascii 160),
    interest-tags: (list 5 (string-ascii 30))
  }
)

;; Profile data visibility configuration
(define-map data-access-settings
  { participant-id: uint, observer-address: principal }
  { access-enabled: bool }
)

;; Engagement tracking ledger
(define-map participant-engagement-metrics
  { participant-id: uint }
  {
    recent-session: uint,
    session-counter: uint,
    recent-interaction: (string-ascii 50)
  }
)

;; ===============
;; System Parameters
;; ===============

;; Error response definitions
(define-constant ACCESS-DENIED (err u500))
(define-constant ENTITY-MISSING (err u501))
(define-constant ALREADY-REGISTERED (err u502))
(define-constant INVALID-PARAMETERS (err u503))
(define-constant OPERATION-RESTRICTED (err u504))

;; Administrative settings
(define-constant PLATFORM-ADMIN tx-sender)

;; ===============
;; State Variables
;; ===============

;; Registry size tracker
(define-data-var participant-tally uint u0)

;; ===============
;; Utility Functions
;; ===============

;; Verify participant record exists
(define-private (participant-registered? (participant-id uint))
  (is-some (map-get? participant-registry { participant-id: participant-id }))
)

;; Confirm ownership of participant profile
(define-private (verify-participant-ownership? (participant-id uint) (address principal))
  (match (map-get? participant-registry { participant-id: participant-id })
    profile-data (is-eq (get crypto-address profile-data) address)
    false
  )
)

;; Validate individual interest tag format
(define-private (validate-interest-tag? (tag (string-ascii 30)))
  (and
    (> (len tag) u0)
    (< (len tag) u31)
  )
)

;; Validate complete interest tag collection
(define-private (validate-interest-collection? (tags (list 5 (string-ascii 30))))
  (and
    (> (len tags) u0)
    (<= (len tags) u5)
    (is-eq (len (filter validate-interest-tag? tags)) (len tags))
  )
)

;; ===============
;; Core Functions
;; ===============

;; Register new participant profile
(define-public (create-participant-profile 
    (display-handle (string-ascii 50)) 
    (personal-description (string-ascii 160)) 
    (interest-tags (list 5 (string-ascii 30))))
  (let
    (
      (new-id (+ (var-get participant-tally) u1))
    )
    ;; Parameter validation checks
    (asserts! (and (> (len display-handle) u0) (< (len display-handle) u51)) INVALID-PARAMETERS)
    (asserts! (and (> (len personal-description) u0) (< (len personal-description) u161)) INVALID-PARAMETERS)
    (asserts! (validate-interest-collection? interest-tags) INVALID-PARAMETERS)

    ;; Create participant record
    (map-insert participant-registry
      { participant-id: new-id }
      {
        display-handle: display-handle,
        crypto-address: tx-sender,
        onboarding-timestamp: block-height,
        personal-description: personal-description,
        interest-tags: interest-tags
      }
    )

    ;; Initialize data access permissions
    (map-insert data-access-settings
      { participant-id: new-id, observer-address: tx-sender }
      { access-enabled: true }
    )

    ;; Update counter
    (var-set participant-tally new-id)
    (ok new-id)
  )
)

;; Modify participant's interest tag collection
(define-public (modify-participant-interests (participant-id uint) (updated-interests (list 5 (string-ascii 30))))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-id: participant-id }) ENTITY-MISSING))
    )
    ;; Security and validation checks
    (asserts! (participant-registered? participant-id) ENTITY-MISSING)
    (asserts! (is-eq (get crypto-address profile-data) tx-sender) OPERATION-RESTRICTED)
    (asserts! (validate-interest-collection? updated-interests) INVALID-PARAMETERS)

    ;; Update interests
    (map-set participant-registry
      { participant-id: participant-id }
      (merge profile-data { interest-tags: updated-interests })
    )
    (ok true)
  )
)

;; Enroll new community participant
(define-public (enroll-new-participant 
    (display-handle (string-ascii 50)) 
    (personal-description (string-ascii 160)) 
    (interest-tags (list 5 (string-ascii 30))))
  (let
    (
      (new-id (+ (var-get participant-tally) u1))
    )
    ;; Validate input parameters
    (asserts! (and (> (len display-handle) u0) (< (len display-handle) u51)) INVALID-PARAMETERS)
    (asserts! (and (> (len personal-description) u0) (< (len personal-description) u161)) INVALID-PARAMETERS)
    (asserts! (validate-interest-collection? interest-tags) INVALID-PARAMETERS)

    ;; Create participant profile
    (map-insert participant-registry
      { participant-id: new-id }
      {
        display-handle: display-handle,
        crypto-address: tx-sender,
        onboarding-timestamp: block-height,
        personal-description: personal-description,
        interest-tags: interest-tags
      }
    )

    ;; Configure initial access permissions
    (map-insert data-access-settings
      { participant-id: new-id, observer-address: tx-sender }
      { access-enabled: true }
    )

    ;; Increment registry counter
    (var-set participant-tally new-id)
    (ok new-id)
  )
)

;; Update participant display handle
(define-public (update-display-handle (participant-id uint) (new-handle (string-ascii 50)))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-id: participant-id }) ENTITY-MISSING))
    )
    ;; Validation checks
    (asserts! (participant-registered? participant-id) ENTITY-MISSING)
    (asserts! (is-eq (get crypto-address profile-data) tx-sender) OPERATION-RESTRICTED)
    (asserts! (and (> (len new-handle) u0) (< (len new-handle) u51)) INVALID-PARAMETERS)

    ;; Update handle
    (map-set participant-registry
      { participant-id: participant-id }
      (merge profile-data { display-handle: new-handle })
    )
    (ok true)
  )
)

;; ===============
;; Enhanced Functions
;; ===============

;; Optimized interest tag update function
(define-public (streamlined-interest-update (participant-id uint) (new-interests (list 5 (string-ascii 30))))
  (begin
    ;; Validation prerequisites
    (asserts! (participant-registered? participant-id) ENTITY-MISSING)
    (asserts! (validate-interest-collection? new-interests) INVALID-PARAMETERS)

    ;; Process the update
    (map-set participant-registry
      { participant-id: participant-id }
      (merge (unwrap! (map-get? participant-registry { participant-id: participant-id }) ENTITY-MISSING) 
             { interest-tags: new-interests })
    )
    (ok "Interest tags successfully updated")
  )
)

;; Profile access control enforcement
(define-public (enforce-profile-access-control (participant-id uint) (address principal))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-id: participant-id }) ENTITY-MISSING))
    )
    ;; Verify access permissions
    (asserts! (is-eq (get crypto-address profile-data) address) OPERATION-RESTRICTED)
    (ok true)
  )
)

;; Comprehensive profile update with validation
(define-public (comprehensive-profile-update 
    (participant-id uint) 
    (new-handle (string-ascii 50)) 
    (new-description (string-ascii 160)) 
    (new-interests (list 5 (string-ascii 30))))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-id: participant-id }) ENTITY-MISSING))
    )
    ;; Extensive validation checks
    (asserts! (participant-registered? participant-id) ENTITY-MISSING)
    (asserts! (is-eq (get crypto-address profile-data) tx-sender) OPERATION-RESTRICTED)
    (asserts! (> (len new-handle) u0) INVALID-PARAMETERS)
    (asserts! (< (len new-handle) u51) INVALID-PARAMETERS)
    (asserts! (> (len new-description) u0) INVALID-PARAMETERS)
    (asserts! (< (len new-description) u161) INVALID-PARAMETERS)
    (asserts! (validate-interest-collection? new-interests) INVALID-PARAMETERS)

    ;; Apply comprehensive update
    (map-set participant-registry
      { participant-id: participant-id }
      (merge profile-data { 
        display-handle: new-handle, 
        personal-description: new-description, 
        interest-tags: new-interests 
      })
    )
    (ok true)
  )
)

;; Authenticate participant ownership claim
(define-public (authenticate-profile-claim (participant-id uint) (claimant-address principal))
  (let
    (
      (profile-data (unwrap! (map-get? participant-registry { participant-id: participant-id }) ENTITY-MISSING))
    )
    ;; Return ownership verification result
    (ok (is-eq claimant-address (get crypto-address profile-data)))
  )
)

;; Record participant platform engagement
(define-public (log-participant-session (participant-id uint))
  (let
    (
      (current-metrics (default-to 
        { recent-session: u0, session-counter: u0, recent-interaction: "None" }
        (map-get? participant-engagement-metrics { participant-id: participant-id })))
    )
    ;; Verify participant exists
    (asserts! (participant-registered? participant-id) ENTITY-MISSING)

    ;; Update engagement metrics
    (map-set participant-engagement-metrics
      { participant-id: participant-id }
      {
        recent-session: block-height,
        session-counter: (+ (get session-counter current-metrics) u1),
        recent-interaction: "session-login"
      }
    )
    (ok true)
  )
)

;; Record detailed participant activity
(define-public (log-participant-activity (participant-id uint) (activity-type (string-ascii 50)))
  (let
    (
      (current-metrics (default-to 
        { recent-session: u0, session-counter: u0, recent-interaction: "None" }
        (map-get? participant-engagement-metrics { participant-id: participant-id })))
    )
    ;; Verify participant exists
    (asserts! (participant-registered? participant-id) ENTITY-MISSING)
    (asserts! (and (> (len activity-type) u0) (< (len activity-type) u51)) INVALID-PARAMETERS)

    ;; Update engagement metrics with specific activity
    (map-set participant-engagement-metrics
      { participant-id: participant-id }
      {
        recent-session: block-height,
        session-counter: (get session-counter current-metrics),
        recent-interaction: activity-type
      }
    )
    (ok true)
  )
)

