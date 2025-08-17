import { writeToEnvFile } from "../utils/helper";
import { aptos, getSigner } from "../utils/aptos_utils";
const { ACCOUNT } = require("../utils/constants");
const MODULE = "lending_actions";

const GENERAL_VAULT = "general_vault";

import {
    InputViewFunctionData 
} from "@aptos-labs/ts-sdk";

async function init_vault() {
    const signer = await getSigner();

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::init_vault`,
                functionArguments: [],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);

    const payload: InputViewFunctionData = {
        function: `${ACCOUNT}::${MODULE}::get_lending_vault_address`,
        typeArguments: [],
        functionArguments: [],
    };
    const data = await aptos.view({payload});

    const vaultAddress = data[0];

    writeToEnvFile("LENDING_VAULT", vaultAddress.toString());
}

async function main() {
    await init_vault();
}

main();
