module myAddress::DaoContract{
    use std::signer;
    // use aptos_framework::coin;
    use std::vector;
    use aptos_std::table::{Self,Table};
    use std::string::{Self,String};
    use myAddress::Dao_events::{Self, dao_created_event};
    use std::account;
    use std::timestamp;
    use std::bcs;
    use aptos_token::property_map::PropertyMap;
    use aptos_token::property_map;    
    struct DaoStruct has key{
        name: String,
        resolve_threshold: u64,
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

    struct AllProposals has key,store{
        all_proposals:vector<Proposal>,
    }

    struct Proposal has store{
        name:String,
        description:String,
        function_name: String,
        /// The list of function arguments corresponding to the functions to be executed
        function_args: PropertyMap,
        voting_start_time:u64,
        voting_end_time:u64,
        proposal_id:u64,
        status:ProposalStatus,
        stats:ProposalStats,
    }

    struct ProposalStatus has key,store{
        NotActive:bool,
        Active:bool,
        Expired:bool,
        Completed:bool,

    }

    struct ProposalStats has key,store{
        total_yes:u64,
        total_no:u64,
        add_to_yes_vote:Table<address,u64>,
        add_to_no_vote:Table<address,u64>,
    }

    const E_DAO_CONTRACT_NOT_EXIST:u64=0;
    const E_INVALID_TIMESTAMP:u64=1;



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
            move_to(&dao_contract_signer,DaoStruct{
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

            // Creating the struct and move it to all proposals
            move_to(&dao_contract_signer,AllProposals{
                all_proposals:vector::empty<Proposal>(),
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

    public fun create_proposal(
        account:&signer,
        dao_contract_address:address,
        name:String,
        description:String,
        function_name: String,// 3 types of functions are supported: (1) "offer_nft", (2) "transfer_fund"
        arg_names: vector<String>,// name of the arguments of the function to be called. The arg here should be the same as the argument used in the function
        arg_values: vector<vector<u8>>,// bcs serailized values of argument values
        arg_types:vector<String>,// types of arguments. currently, we only support string, u8, u64, u128, bool, address.
        voting_start_time:u64,
        voting_end_time:u64,
    ) acquires DaoStruct,AllProposals{
        assert!(exists<DaoStruct>(dao_contract_address),E_DAO_CONTRACT_NOT_EXIST);
        // Check the timestamp is from future and is greater than end time
        assert!(voting_start_time > voting_end_time && voting_start_time>timestamp::now_seconds(),E_INVALID_TIMESTAMP);
        let prop_map=property_map::new(arg_names,arg_values,arg_types);
        checkFunction(function_name,prop_map);

        let account_addr=signer::address_of(account);
        let dao_contract=borrow_global_mut<DaoStruct>(dao_contract_address);

        let proposals=borrow_global_mut<AllProposals>(dao_contract_address);
        let vec=&mut proposals.all_proposals;
        vector::push_back( vec,Proposal{
            name:name,
            description:description,
            function_name:function_name,
            function_args:prop_map,
            voting_start_time:voting_start_time,
            voting_end_time:voting_end_time,
            proposal_id:dao_contract.next_proposal_id,
            status:ProposalStatus{
                NotActive:true,
                Active:false,
                Expired:false,
                Completed:false,
            },
            stats:ProposalStats{
                total_yes:0,
                total_no:0,
                add_to_yes_vote:table::new<address, u64>(),
                add_to_no_vote:table::new<address, u64>(),                
            }
        })
        
    }

    public fun checkFunction(
        function_name:String,
        map:PropertyMap
        ) {
        let transfer_fund=string::utf8(b"transfer_fund");
        let offer_nft=string::utf8(b"offer_nft");
        if (function_name==transfer_fund ){
            property_map::read_address(&map,&string::utf8(b"dst"));
            property_map::read_u64(&map,&string::utf8(b"amount"));
        }else {
            property_map::read_address(&map,&string::utf8(b"creator"));
            property_map::read_address(&map,&string::utf8(b"dst"));
            property_map::read_u64(&map,&string::utf8(b"property_version"));
            property_map::read_string(&map,&string::utf8(b"collection"));
            property_map::read_string(&map,&string::utf8(b"token_name"));
        }

    }

    // public fun checkValues(value:)


}