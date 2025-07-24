import {
  Account,
  Aptos,
  AptosConfig,
  Ed25519PrivateKey,
  HexInput,
  Network,
  NetworkToNetworkName
} from "@aptos-labs/ts-sdk";
import * as dotenv from "dotenv";
dotenv.config();

const APTOS_NETWORK: Network = NetworkToNetworkName[Network.MAINNET];
const config = new AptosConfig({ network: APTOS_NETWORK });
const aptos = new Aptos(config);

const OWNER_PRIVATE_KEY = process.env.PRIVATE_KEY as HexInput;

const getSigner = async () => {
  const privateKey = new Ed25519PrivateKey(OWNER_PRIVATE_KEY);
  const signer = Account.fromPrivateKey({ privateKey }); // ✅ correct usage
  return signer;
};

export { getSigner, aptos };

async function main() {
  const signer = await getSigner();
  console.log("Address:", signer.accountAddress);
}

main();
