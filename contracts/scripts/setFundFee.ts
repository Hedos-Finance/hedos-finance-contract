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
const MODULE = "general_vault";

async function fundFeeCurrent() {
    let payload;
    payload = {
        function: `${ACCOUNT}::fund_fee::fund_fee_current`,
        typeArguments: [],
        functionArguments: [],
    };
    let result = await aptos.view({ payload });

    console.log("vault", `${result}`);
}
async function setFundFee() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::set_fund_fee`,
                functionArguments: ["2557826", false],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

async function main() {
    // await fundFeeCurrent();
    await setFundFee();
}

main();