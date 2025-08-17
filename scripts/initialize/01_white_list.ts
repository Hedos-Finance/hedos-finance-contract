import { aptos, getSigner } from "../utils/aptos_utils";
const { ACCOUNT } = require("../utils/constants");
const MODULE = "white_list";


async function init_white_list() {
    const signer = await getSigner();

    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::init_white_list`,
                functionArguments: [],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}


async function main() {
    await init_white_list();
}

main();