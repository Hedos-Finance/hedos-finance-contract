import { writeToEnvFile } from "../utils/helper";
import { aptos, getSigner } from "../utils/aptos_utils";
const { ACCOUNT } = require("../utils/constants");
const MODULE = "general_vault";

async function init_interact_address() {
    const signer = await getSigner();

    const LENDING = process.env.LENDING_VAULT;  
    const LIQUID = process.env.LIQUID_VAULT;
    const PERP = process.env.SHORT;

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::init_interact_address`,
                functionArguments: [LENDING.toString(), LIQUID.toString(), PERP.toString()],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function main() {
    await init_interact_address();
}

main();