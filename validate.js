// npm i truffle-contract-schema
// npm i truffle-contract-schema@3.0.11
// npm i truffle-contract-schema@"^3.0.11"/
//

// const { normalize, validate } = require('truffle-contract-schema')
const { normalize, validate } = require('@truffle/contract-schema')

const testArtifact = (subject, msg) => {
  try {
    let normalized, validated

    console.log(`Subject: ${msg}`)
    console.log(`Subject SchemaVersion: ${subject.schemaVersion}`)
    normalized = normalize(subject)
    console.log(`Normalized SchemaVersion: ${normalized.schemaVersion}`)
    validated = validate(normalized)
    console.log('Validation OK\n\n', )
  } catch(e) {
    console.log('Validation FAILED\n', )
    console.log(e.errors)
    console.log(e)
    console.log('\n\n')
  }
}

const migrations = require('./build/contracts/migrations.json')
const supplyChain = require('./build/contracts/SupplyChain.json')
const supplyChainState = require('./build/contracts/SupplyChainState.json')

// testArtifact(migrations, 'migrations.json')
testArtifact(supplyChain, 'SupplyChain.json')
// testArtifact(supplyChainState, 'SupplyChainState.json')
