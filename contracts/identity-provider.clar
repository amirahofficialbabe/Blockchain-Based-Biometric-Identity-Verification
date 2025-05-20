;; Identity Provider Verification Contract
;; This contract validates credential issuers and maintains a registry of trusted providers

(define-data-var admin principal tx-sender)

;; Map of verified identity providers
(define-map verified-providers
  principal  ;; provider's principal
  {
    name: (string-utf8 100),
    verified: bool,
    verification-date: uint,
    reputation-score: uint
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-REGISTERED u101)
(define-constant ERR-NOT-FOUND u102)

;; Register a new identity provider
(define-public (register-provider (provider-principal principal) (provider-name (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-none (map-get? verified-providers provider-principal)) (err ERR-ALREADY-REGISTERED))

    (map-set verified-providers
      provider-principal
      {
        name: provider-name,
        verified: false,
        verification-date: u0,
        reputation-score: u0
      }
    )
    (ok true)
  )
)

;; Verify an identity provider
(define-public (verify-provider (provider-principal principal))
  (let ((provider (unwrap! (map-get? verified-providers provider-principal) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))

    (map-set verified-providers
      provider-principal
      (merge provider {
        verified: true,
        verification-date: block-height
      })
    )
    (ok true)
  )
)

;; Update provider reputation score
(define-public (update-reputation (provider-principal principal) (score uint))
  (let ((provider (unwrap! (map-get? verified-providers provider-principal) (err ERR-NOT-FOUND))))
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))

    (map-set verified-providers
      provider-principal
      (merge provider {
        reputation-score: score
      })
    )
    (ok true)
  )
)

;; Check if a provider is verified
(define-read-only (is-verified-provider (provider-principal principal))
  (match (map-get? verified-providers provider-principal)
    provider (ok (get verified provider))
    (err ERR-NOT-FOUND)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)
