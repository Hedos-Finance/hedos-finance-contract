import { aptos, getSigner } from "./aptos_utils";

const ACCOUNT = "0b625e2c4582203073b54cded720782bd87b059ba98d8229177baf16b969c5d9";
const MODULE = "interact_amnis";

async function unstake(){
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::unstake_amAPT`,
                functionArguments: [17_000_000, signer.accountAddress],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}
async function stake() {
    const signer = await getSigner();
    const transaction = await aptos.transaction.build.simple(
        {
            sender: signer.accountAddress,
            data: {
                function: `${ACCOUNT}::${MODULE}::stake`,
                functionArguments: [20_000_000, signer.accountAddress],
            }
        }
    )

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });

    const executedTransaction = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash });
    console.log(executedTransaction);
}
async function main() {
    await stake();
    // await unstake();
}



main();