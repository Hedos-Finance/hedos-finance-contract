import { aptos, getSigner } from "./utils/aptos_utils";
import { InputViewFunctionData } from "@aptos-labs/ts-sdk";
import * as fs from "fs";

const HYPERION = "0x8b4a2c4bb53857c718a04c020b98f8c2e1f99a68b0f57389a8bf5434cd22e05c";
const MODULE = "pool_v3";

async function main() {
    const signer = await getSigner();

    const payload: InputViewFunctionData = {
        function: `${HYPERION}::${MODULE}::all_pools`,
        typeArguments: [],
        functionArguments: [],
    };

    const data = await aptos.view({ payload });

    // console.log("All Pools:", data);
    const addresses = data.flat().map((item: any) => item.inner);

    // console.log("Addresses:", addresses);

    for (let idx in addresses) {
        const addr = addresses[idx];
        if (197 <= parseInt(idx)) {
            const liquidityPayload: InputViewFunctionData = {
                function: `${HYPERION}::${MODULE}::get_pool_liquidity`,
                typeArguments: [],
                functionArguments: [addr],
            };

            const data_liquidity = await aptos.view({ payload: liquidityPayload });
            const liquidity = data_liquidity[0].valueOf();
            if (BigInt(String(liquidity)) > 0n) {
                const infoPayload: InputViewFunctionData = {
                    function: `${HYPERION}::${MODULE}::liquidity_pool_info`,
                    typeArguments: [],
                    functionArguments: [addr],
                };
                const dataInfo = await aptos.view({ payload: infoPayload });
                console.log(`${addr}:`, liquidity, dataInfo);
                fs.appendFileSync("./hyperion.txt", `${idx}  ` + `${addr}:` + '\n' + liquidity + '\n' + dataInfo + '\n=======================\n', "utf-8");
            }
            // fs.appendFileSync("./address.txt", addr + "\n", "utf-8");
        }
    }
    console.log("✅ Saved to hyperion.txt");
}

main();
