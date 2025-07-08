
import {
    Account,
    Aptos,
    AptosConfig,
    Ed25519PrivateKey,
    HexInput,
    Network,
    NetworkToNetworkName
} from "@aptos-labs/ts-sdk";
import { aptos, getSigner } from "../aptos_utils";

const Hyperrion = "0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c";
const MODULE = "router_v3";

async function test() {
    const signer = await getSigner();
    const lpPath = ["0xd3894aca06d5f42b27c89e6f448114b3ed6a1ba07f992a58b2126c71dd83c127", "0x18269b1090d668fbbc01902fa6a5ac6e75565d61860ddae636ac89741c883cbc"]; // vector<address>
    const amountIn = "100000000"; // 100 USDC (giả sử 6 decimals)
    const fromToken = "0xbae207659db88bea0cbead6da0ed00aac12edcdda169e591cd41c94180b46f3b"; // object address của Metadata
    const toToken = "0xa";     // object address của Metadata

    let payload;
    payload = {
        function: `${Hyperrion}::${MODULE}::get_batch_amount_out`,
        typeArguments: [],
        functionArguments: [lpPath, amountIn, fromToken, toToken],
    };
    let result = await aptos.view({ payload });

    console.log("address vault", `${result}`);
}

async function main() {
    await test();
}

main();