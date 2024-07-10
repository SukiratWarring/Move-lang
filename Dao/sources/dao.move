module myAddress::DaoContract{
    use std::signer;
    // use aptos_framework::coin;
    // use std::vector;
    use aptos_std::table::{Self,Table};
    use std::string::String;
    use myAddress::Dao_events::{Self, dao_created_event};
    use std::account;
    use std::bcs;
    struct Dao has key{
        name: String,
        resolve_threshold: u64,
        /// The NFT Collection that is used to govern the DAO.
        governance_token: GovernanceToken,
        voting_duration: u64,
        min_required_proposer_voting_power: u64,
        next_proposal_id: u64,
        dao_signer_capability: account::SignerCapability,
        admin: address,

    }

    struct GovernanceToken has store,drop{
        creator: address,
        collection: String,
    }

    struct AllProposals has key{
        all_proposals:Table<u64, Proposal>
    }

    struct Proposal has store{
        name:String,
        description:String,
        proposer:address,
        voting_power:u64,
        voting_start_time:u64,
        voting_end_time:u64,
        proposal_id:u64,
        status:ProposalStatus,
        stats:ProposalStats,
    }

    struct ProposalStatus has store{
        NotActive:bool,
        Active:bool,
        Expired:bool,
        Completed:bool,

    }

    struct ProposalStats has store{
        total_yes:u64,
        total_no:u64,
        add_to_yes_vote:u64,
        add_to_no_vote:u64,
    }



    public fun create_dao_contract(
        dao_creator:&signer,
        name: String,
        resolve_threshold: u64,
        governance_token_creator:address,
        governance_token_collection_name:String,
        voting_duration: u64,
        min_voting_power:u64,
        ):address{
            let seed=bcs::to_bytes(&name);
            let dao_creator_addr=signer::address_of(dao_creator);
            let (dao_contract_signer,dao_contract_signer_cap)=account::create_resource_account(dao_creator,seed);
            let dao_contract_address=signer::address_of(&dao_contract_signer);
            // Moving the dao_contract to dao contract signer
            move_to(&dao_contract_signer,Dao{
                name:name,
                resolve_threshold:resolve_threshold,
                governance_token:GovernanceToken{
                    creator:governance_token_creator,
                    collection:governance_token_collection_name
                },
                voting_duration:voting_duration,
                min_required_proposer_voting_power:min_voting_power,
                next_proposal_id:1,
                dao_signer_capability:dao_contract_signer_cap,
                admin:dao_creator_addr,
            });

            // Creating the structs and moving them
            move_to(&dao_contract_signer,AllProposals{
                all_proposals:table::new<u64, Proposal>(),
            });

            dao_created_event(
                name,
                resolve_threshold,
                voting_duration,
                min_voting_power,
                1,
                dao_creator_addr,
                dao_contract_address
            );
            dao_contract_address

    } 


}