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
