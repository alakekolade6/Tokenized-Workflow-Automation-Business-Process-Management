;; Process Designer Verification Contract
;; Validates and manages business process designers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_DESIGNER (err u103))

;; Data structures
(define-map verified-designers principal bool)
(define-map designer-credentials principal {
    name: (string-ascii 50),
    certification-level: uint,
    verified-at: uint,
    reputation-score: uint
})

;; Read-only functions
(define-read-only (is-verified-designer (designer principal))
    (default-to false (map-get? verified-designers designer))
)

(define-read-only (get-designer-credentials (designer principal))
    (map-get? designer-credentials designer)
)

(define-read-only (get-designer-reputation (designer principal))
    (match (map-get? designer-credentials designer)
        credentials (get reputation-score credentials)
        u0
    )
)

;; Public functions
(define-public (verify-designer (designer principal) (name (string-ascii 50)) (cert-level uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (not (is-verified-designer designer)) ERR_ALREADY_VERIFIED)
        (asserts! (> cert-level u0) ERR_INVALID_DESIGNER)

        (map-set verified-designers designer true)
        (map-set designer-credentials designer {
            name: name,
            certification-level: cert-level,
            verified-at: block-height,
            reputation-score: u100
        })
        (ok true)
    )
)

(define-public (update-reputation (designer principal) (new-score uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-verified-designer designer) ERR_NOT_FOUND)

        (match (map-get? designer-credentials designer)
            credentials (begin
                (map-set designer-credentials designer
                    (merge credentials { reputation-score: new-score }))
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

(define-public (revoke-verification (designer principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-verified-designer designer) ERR_NOT_FOUND)

        (map-delete verified-designers designer)
        (map-delete designer-credentials designer)
        (ok true)
    )
)
