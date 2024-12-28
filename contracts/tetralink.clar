;; TetraLink Network Contract
;; Service discovery and connection network for microservices

;; Constants
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant MAX_SERVICE_NAME_LENGTH u64)

;; Data structures
(define-map services
    { service-id: uint }
    {
        name: (string-ascii 64),
        owner: principal,
        endpoint: (string-ascii 256),
        status: (string-ascii 16),
        last-heartbeat: uint
    }
)

(define-map service-names
    { name: (string-ascii 64) }
    { service-id: uint }
)

;; Data variables
(define-data-var next-service-id uint u1)

;; Private functions
(define-private (validate-service-name (name (string-ascii 64)))
    (let
        ((length (len name)))
        (and (> length u0) (<= length MAX_SERVICE_NAME_LENGTH))
    )
)

;; Public functions
(define-public (register-service (name (string-ascii 64)) (endpoint (string-ascii 256)))
    (let
        ((service-id (var-get next-service-id)))
        (if (validate-service-name name)
            (if (is-none (map-get? service-names {name: name}))
                (begin
                    (map-set services
                        {service-id: service-id}
                        {
                            name: name,
                            owner: tx-sender,
                            endpoint: endpoint,
                            status: "active",
                            last-heartbeat: block-height
                        }
                    )
                    (map-set service-names
                        {name: name}
                        {service-id: service-id}
                    )
                    (var-set next-service-id (+ service-id u1))
                    (ok service-id)
                )
                ERR_ALREADY_EXISTS
            )
            (err u400)
        )
    )
)

(define-public (unregister-service (service-id uint))
    (let
        ((service (map-get? services {service-id: service-id})))
        (if (and
                (is-some service)
                (is-eq (get owner (unwrap-panic service)) tx-sender)
            )
            (begin
                (map-delete services {service-id: service-id})
                (map-delete service-names {name: (get name (unwrap-panic service))})
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

(define-public (update-status (service-id uint) (new-status (string-ascii 16)))
    (let
        ((service (map-get? services {service-id: service-id})))
        (if (and
                (is-some service)
                (is-eq (get owner (unwrap-panic service)) tx-sender)
            )
            (begin
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) {status: new-status})
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

(define-public (heartbeat (service-id uint))
    (let
        ((service (map-get? services {service-id: service-id})))
        (if (and
                (is-some service)
                (is-eq (get owner (unwrap-panic service)) tx-sender)
            )
            (begin
                (map-set services
                    {service-id: service-id}
                    (merge (unwrap-panic service) {last-heartbeat: block-height})
                )
                (ok true)
            )
            ERR_UNAUTHORIZED
        )
    )
)

;; Read-only functions
(define-read-only (get-service-by-id (service-id uint))
    (ok (map-get? services {service-id: service-id}))
)

(define-read-only (get-service-by-name (name (string-ascii 64)))
    (match (map-get? service-names {name: name})
        service-map (get-service-by-id (get service-id service-map))
        ERR_NOT_FOUND
    )
)

(define-read-only (is-service-active (service-id uint))
    (match (map-get? services {service-id: service-id})
        service (ok (is-eq (get status service) "active"))
        ERR_NOT_FOUND
    )
)