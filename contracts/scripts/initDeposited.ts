import { aptos, getSigner } from "./aptos_utils";
import {
    Account,
    Aptos,
    AptosConfig,
    Ed25519PrivateKey,
    HexInput,
    Network,
    NetworkToNetworkName
} from "@aptos-labs/ts-sdk";

const ACCOUNT = process.env.APTOS_ACCOUNT;
const MODULE = "fund_fee";

async function init_deposited() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::init_total_deposited`,
                functionArguments: [],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function set_current() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::set_current`,
                functionArguments: [360200000, 120200000 ],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}
async function view_current() {
    let payload;
    payload = {
        function: `${ACCOUNT}::${MODULE}::current_deposited`,
        typeArguments: [],
        functionArguments: [],
    };
    let result = await aptos.view({ payload });

    console.log("", `${result}`);

}
async function main() {
    // await set_current();
    await init_deposited();
    // await view_current();

}

main();