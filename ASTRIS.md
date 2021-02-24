# Astris voting protocol

## Note on Hashing and JSON

A lot of data is stored as JSON and therefore there must be a canonical method of formatting it
in order to hash it consistently.
This will be known as canonical encoding.
The canonical JSON encoding will have no unnecessary whitespace and object keys will be sorted alphabetically, noting that all keys will only ever be characters representable in ASCII.

This function will turn any JSON into the canonical form, due the fact that the go JSON decoder will
"unmarshal" into `map[string]interface{}` and will "marshal" a `map` by sorting the keys first.

Not as efficient as laying out the structs in the correct order, but less error prone

```golang
func CanonicalJSONEncoder(out io.Writer) func(v interface{}) error {
    enc := json.NewEncoder(out)
    enc.SetIndent("","")
    enc.SetEscapeHTML(false)
    return func(v interface{}) error {
        b, err := json.Marshal(v)
        if err != nil {
            return err
        }
        var t interface{}
        err = json.Unmarshal(b,&t)
        if err != nil {
            return err
        }
        // t is map[string]interface instead of struct, so the keys will be sorted.
        return enc.Encode(t)
    }
}
```

# Stage 1 Setup

- [organiser] generate initial data:

Note that some of this data must be gathered and organized "off-chain" before the official "genesis" of the chain, as that genesis needs to contain it all.

### Genesis Payload

```json
{
   "name": "Election Name, and any other human readable data, this could even be markdown.",
   "encryptionSharedParams": {
       "p": "elgamal prime",
       "q": "elgamal subgroup prime",
       "g": "elgamal generator over q", // p,q,g are likely from RFC5114 for DHKE
       "t": "threshold for dishonesty", // <- this must be <= l and > l/2 (or something)
       "l": "number of trustees", // <- this should match the trustees array length.
   }
   "candidates": [
       // note that this array is ordered, and each candidate has an implicit "index"
       {
           "candidateId": "opaque", // a uuid-like parameter
           "name": "human readable candidate name"
       }, ...
   ],
   "trustees":[
       // note that this array is ordered, and each trustee has an implicit "index"
       {
           "trusteeId": "opaque", // a uuid-like paramter
           "verificationKey": { PublicKeyData }, // public key for verifying signatures
           "verificationProof": { ZKPoK of SecretKey }, // proof that they know the secret key
           "shardPublicKey": { PublicKeyData }, // this trustee's shard of the public key
           "shardProof": { ZKPoK of shard of SecretKey }, // proof they have the secret key for the shard
       }, ...
   ],
   "timing": {
       // this phase is where the trustees must add blocks to the chain to
       // lengthen it, locking in the parameters.
       "parameterFreeze": {
           "opens": "ISO8601 DateTime in UTC",
           "closes": "ISO8601 DateTime in UTC",// >= parameterFreeze.opens
       },
       // now the voters may register with the registrar during this period.
       // this creates the relationship between the registrars list of voter ids
       // and the keys the voters will use to sign their votes to prove their validity
       "voterRegistration": {
           "opens": "ISO8601 DateTime in UTC", // >= parameterFreeze.closes
           "closes": "ISO8601 DateTime in UTC", // >= voterRegistration.opens
       },
       // the vote casting phase, voters will use the election public key and their own
       // signing keys to cast votes. Duplicates will be know as the voter id is included
       // in the data.
       "voteCasting": {
           "opens": "ISO8601 DateTime in UTC", // >= voterRegistration.closes
           "closes": "ISO8601 DateTime in UTC", // >= voteCasting.opens
       },
       // The final phase is tallying the votes. Anyone can tally, but the trustees must decrypt.
       "tallyDecryption": {
           "opens": "ISO8601 DateTime in UTC", // >= voteCasting.opens
           "closes": "ISO8601 DateTime in UTC", // >= tallyDecryption.opens
       }
   },
   "registrar": {
       "registrarId": "opaqueId",
       "name": "human readable name of registration authority",
       "verificationKey": { PublicKeyData },
       "verificationProof": { ZKPoK of SecretKey },
       "elgibilityDataURL": "https://...", // URL to the eligibility data (can be shared P2P after initial download)
       "elgibilityDataHash": "sha256:...", // integrity check for the eligibility data
       "registrationURL": "https://...", // URL where voters can go to authenticate and get their public keys signed by the registrar, they can then publish their keys on the blockchain.
   }
}
```

The eligibility data is a list of ID's of voters that can participate in the election. The id's should be opaque enough that only the registrar (and subsequently the voter) knows which is which.

### Eligibility Data

```json
{
    "count": "number", // stored as a string as it could be big.
    "voters": [
        "opaque id",
        "opaque id",
        ...
    ]
}
```

### Parameter confirmation

During the parameter freeze time period: the registrar and trustees must each sign a block to be added to the chain to show that they agree with the parameters as set. They can sign many (increasing chain depth), but with a new `nonce` for each block. The payload will have the form:

```json
{
    "electionId": "hash of the genesis block",
    "participantId": "trustee or registrar id", // they should all be unique
    "nonce": "some random data, say 256bits, in hex",
    "signature": { Signature with participant private key } // msg is 'electionId|participantId|nonce`
}
```

At least one confirmation from each participant must be made within the time frame for the election to be valid to continue.

### VoterRegistration

This phase requires each voter to generate a keypair and get the registrar to sign the public key. This is
done out of band, and the voter can either mint their own block with the signature, or the registrar can do it. The important bit is that the signature ends up on the chain and is verified by the voter.

The exact protocol for authentication and passing the public key to the registrar for signing is out of scope. This scheme defines a `registrationURL` that, when opened in a webview/browser should present the use with the opportunity to authenticate and provide a public key.

The registrar will then create a message to be put on the chain:

```json
{
    "electionId": "...",
    "registrarId": "...",
    "voterId": "...",
    "publicKey": { VoterPublicKey },
    "signature": { Signature with registrar private key }
}
```

This continues until `timing.voterRegistration.closes`.

### VoteCasting

Once the voters are registered, the voting begins. Each voter may now vote by encrypting NUM_CANDIDATES choices in an array, one for each candidate. The vote itself consists of a ciphertext and a ZKP that the ciphertext encodes `0` or `1` (or the exponential elgamal equivalent, 0 or `q`).
Along with the choices is another ZKP that the sum of the ciphertexts also encodes a `0` or `1`: zero being abstainance, 1 being a vote (NB this could be extended to prove sum < a configured number of candidates).

Finally there is a signature over the vote from the voter's secret key, to show they placed the vote.

```json
{
    "electionId": "...",
    "voterId": "...", // to reference the public key earlier in the chain, used to prevent double-voting
    "votes": [
        // NB in order of candidates in the parameters, and always the full list
        {
            "ciphertext": { CipherText }, // encrypted with the election public key
            "proof": { ZKP of ciphertext being 0 or 1 }
        }, ...
    ],
    "proof": { ZKP of sum of ciphertexts being 0 or 1 }, // we can add them ourselves
    "fingerprint": "sha256 hash of the rest of the data except the signature", // explicit as it is receipt
    "signature": { Signature with voter private key }, // signature over the fingerprint
}
```

Votes may be cast from `timing.voteCasting.opens` to `timing.voteCasting.closes`.

### TallyDecryption

Once voting is closed, the tally can be created. It does not need to be added to the chain directly, as each node will need to calculate it, but we will include it in each partial decryption to show that the
summation by each node was correct

```json
{
    "electionId": "...",
    "trusteeId": "...",
    "encrypted": [ // in order of candidates
        { CipherText },
        { CipherText },
        { CipherText },
        { CipherText }, ...
    ],
    "decrypted": [ // in order of candidates
        {
            // I still don't quite know how these are represented
            "partial": { ... },
            "proof": { ZKP of decryption }
        }, ...
    ],
    "signature": { Signature over result with trustee secret key }
}
```

Once the partial decryptions have been verified by the proofs, we can combine them all into the final decrypted value. As this is done with exponential ElGamal, we need to lower the results back down to the discrete log. This means we need to calculate the discrete log over P of NUM_VOTERS (as that is the highest possible value), well, we don't we can generate the table lazily as we go, as we likely won't get such a convincing majority as 100%.

The final result does not need to be published on the chain, as it would need to be calculated to verify the block if it was, and so we need not do that on-chain. Implementations will likely cache the results (and the encrypted tally's) as they go along to use as a "trusted" checkpoint to save the costly recalculation.

### Verification

The same process that ensure the chain integrity is also the verification for the election. So the verification step is exactly the same as the blockchain verification.
