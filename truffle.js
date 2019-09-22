module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  compilers: {
    solc: {
      version: "^0.5.11"
    }
  },
  networks: {
    development: {
      gas: 6721975,
      host: "127.0.0.1",
      port: 8545,
      // port: 7545, // Petshop had this as 7545
      network_id: "*" // Match any network id
    },
    develop: {
      port: 8545
    }
  }
};


// module.exports = {
//   networks: {
//     development: {
//       host: "127.0.0.1",
//       port: 8545,
//       network_id: '*',
//       gas: 6721975
//     }
//   },
//   compilers: {
//     solc: {
//       version: "^0.5.11"
//     }
//   }
// };