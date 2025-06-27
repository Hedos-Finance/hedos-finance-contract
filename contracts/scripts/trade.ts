import { aptos, getSigner } from "./aptos_utils";

const ACCOUNT = "70e9853c05beac263a6fee5dd46989540dc59694ec84456c79f1751da803e102";
const MODULE = "interact_merkle_trade";

async function main() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::simple_trade`,
                functionArguments: [signer.accountAddress, 200_000, 150, true, "APT_USD"],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}

main();