[Previous test content remains...]

Clarinet.test({
    name: "Enforces heartbeat rate limiting",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const serviceName = "test-service";
        
        // Register service
        let register = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'register-service',
                [
                    types.ascii(serviceName),
                    types.ascii("http://localhost:8080"),
                    types.ascii("1.0.0"),
                    types.none()
                ],
                deployer.address
            )
        ]);

        const serviceId = register.receipts[0].result.expectOk();

        // First heartbeat should succeed
        let heartbeat1 = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'heartbeat',
                [serviceId],
                deployer.address
            )
        ]);
        heartbeat1.receipts[0].result.expectOk().expectBool(true);

        // Immediate second heartbeat should fail
        let heartbeat2 = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'heartbeat',
                [serviceId],
                deployer.address
            )
        ]);
        heartbeat2.receipts[0].result.expectErr(429);
    }
});

[Additional test cases...]
