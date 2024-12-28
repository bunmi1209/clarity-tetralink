import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new service",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const serviceName = "test-service";
        const endpoint = "http://localhost:8080";

        let block = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'register-service',
                [types.ascii(serviceName), types.ascii(endpoint)],
                deployer.address
            )
        ]);

        block.receipts[0].result.expectOk().expectUint(1);
        
        // Verify service registration
        let getService = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'get-service-by-name',
                [types.ascii(serviceName)],
                deployer.address
            )
        ]);

        const serviceData = getService.receipts[0].result.expectOk().expectSome();
        assertEquals(serviceData['name'], serviceName);
        assertEquals(serviceData['endpoint'], endpoint);
        assertEquals(serviceData['owner'], deployer.address);
    }
});

Clarinet.test({
    name: "Cannot register duplicate service names",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const serviceName = "test-service";
        const endpoint = "http://localhost:8080";

        let block = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'register-service',
                [types.ascii(serviceName), types.ascii(endpoint)],
                deployer.address
            ),
            Tx.contractCall(
                'tetralink',
                'register-service',
                [types.ascii(serviceName), types.ascii(endpoint)],
                deployer.address
            )
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(409);
    }
});

Clarinet.test({
    name: "Can update service status",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const serviceName = "test-service";
        const endpoint = "http://localhost:8080";

        // Register service
        let register = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'register-service',
                [types.ascii(serviceName), types.ascii(endpoint)],
                deployer.address
            )
        ]);

        const serviceId = register.receipts[0].result.expectOk();

        // Update status
        let update = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'update-status',
                [serviceId, types.ascii("inactive")],
                deployer.address
            ),
            // Unauthorized update attempt
            Tx.contractCall(
                'tetralink',
                'update-status',
                [serviceId, types.ascii("active")],
                wallet1.address
            )
        ]);

        update.receipts[0].result.expectOk().expectBool(true);
        update.receipts[1].result.expectErr(401);
    }
});