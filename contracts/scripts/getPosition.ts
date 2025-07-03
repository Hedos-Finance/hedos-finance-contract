
import { Aptos } from "@aptos-labs/ts-sdk";
import { MerkleClient, MerkleClientConfig } from "@merkletrade/ts-sdk";
async function main() {
    const merkle = new MerkleClient(await MerkleClientConfig.mainnet());
    const aptos = new Aptos(merkle.config.aptosConfig);

    const session = await merkle.getPositions({address: "0xea26db38367bcdbacb331422115a25f2e4b819cf514b4215abe83dc38ef9525f"})
    console.log(session);
}

main();