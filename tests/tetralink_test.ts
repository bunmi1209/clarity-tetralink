[Previous test content]

Clarinet.test({
    name: "Can update service heartbeat",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const serviceName = "test-service";
        
        // Register service first
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

        // Update heartbeat
        let heartbeat = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'heartbeat',
                [serviceId],
                deployer.address
            )
        ]);

        heartbeat.receipts[0].result.expectOk().expectBool(true);
    }
});

[Additional test cases for new functions]
