const HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic = process.env.MNEMONIC
const ropsten_endpoint = process.env.ROPSTEN_ENDPOINT

module.exports = {
  plugins: ['txlog-to-plantuml'],

  compilers: {
    solc: {
      version: "0.7.3"
    }
  },

  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*'
    },

    ropsten: {
      provider: () => new HDWalletProvider(mnemonic,ropsten_endpoint),
      network_id: 3,       // Ropsten's id
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },

  }
};
