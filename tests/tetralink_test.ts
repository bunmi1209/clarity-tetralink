import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Existing tests remain unchanged
[... existing test content ...]

Clarinet.test({
    name: "Can register service with version and metadata",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const serviceName = "test-service";
        const endpoint = "http://localhost:8080";
        const version = "1.0.0";
        const metadata = JSON.stringify({
            description: "Test service",
            documentation: "http://docs.test.com"
        });

        let block = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'register-service',
                [
                    types.ascii(serviceName),
                    types.ascii(endpoint),
                    types.ascii(version),
                    types.some(types.utf8(metadata))
                ],
                deployer.address
            )
        ]);

        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Can update service version",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const serviceName = "test-service";
        const endpoint = "http://localhost:8080";
        const version = "1.0.0";
        
        let register = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'register-service',
                [
                    types.ascii(serviceName),
                    types.ascii(endpoint),
                    types.ascii(version),
                    types.none()
                ],
                deployer.address
            )
        ]);

        const serviceId = register.receipts[0].result.expectOk();

        let update = chain.mineBlock([
            Tx.contractCall(
                'tetralink',
                'update-service-version',
                [serviceId, types.ascii("1.1.0")],
                deployer.address
            )
        ]);

        update.receipts[0].result.expectOk().expectBool(true);
    }
});
