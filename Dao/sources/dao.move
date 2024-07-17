module myAddress::DaoContract{
    use std::signer;
    use aptos_framework::coin;
    use std::vector;
    use aptos_std::table::{Self,Table};
    use std::string::{Self,String};
    use myAddress::Dao_events::{Self, dao_created_event};
    use std::account;
    use std::timestamp;
    use std::bcs;
    use aptos_framework::account::create_signer_with_capability;
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
        threshhold:u64,
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
    const E_ONLY_ADMIN:u64=2;
    const E_NO_PROPOSALS:u64=3;
    const E_INVALID_PROPOSAL_Id:u64=4;
    const E_PROPOSAL_NOT_STARTED:u64=5;
    const E_INVALID_COIN_TYPE:u64=6;
    const E_THRESHOLD_NOT_MET:u64=7;
    const E_PROPOSAL_ALREADY_STARTED:u64=8;
    const E_NOT_CORRECT_TIME_WINDOW:u64=9;
    const E_ADDRESS_NOT_REGISTERED:u64=10;

    public fun create_dao_contract(
        dao_creator:&signer,
        name: String,
        resolve_threshold: u64,
        governance_token_creator:address,
        governance_token_collection_name:String,
        voting_duration: u64,
        min_voting_power:u64,
        threshhold:u64,
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
                    collection:governance_token_collection_name,
                    threshhold:threshhold
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
        arg_names: vector<String>,
        arg_values: vector<vector<u8>>,
        arg_types:vector<String>, 
        voting_start_time:u64,
        voting_end_time:u64,
    ) acquires DaoStruct,AllProposals{
        assert!(exists<DaoStruct>(dao_contract_address),E_DAO_CONTRACT_NOT_EXIST);
        // Check the timestamp is from future and is greater than end time
        assert!(voting_start_time > voting_end_time && voting_start_time>timestamp::now_seconds(),E_INVALID_TIMESTAMP);
        let prop_map=property_map::new(arg_names,arg_values,arg_types);
        checkFunctionForCreateProposal(function_name,prop_map);

        let account_addr=signer::address_of(account);
        let dao_contract=borrow_global_mut<DaoStruct>(dao_contract_address);

        let proposals=borrow_global_mut<AllProposals>(dao_contract_address);
        let vec=&mut proposals.all_proposals;
        vector::push_back(vec,Proposal{
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

    public fun voteProposal<CoinType>(
        account:&signer,
        dao_contract_address:address,
        proposal_id:u64,
        voteType:bool,//true for "yes"
        voteCount:u64
        ) acquires AllProposals,DaoStruct{
        let addr=signer::address_of(account);
        let proposals=borrow_global_mut<AllProposals>(dao_contract_address);
        let length=vector::length(&proposals.all_proposals);
        //fetch the proposal
        let proposal=vector::borrow_mut<Proposal>(&mut proposals.all_proposals,proposal_id);        
        let dao=borrow_global<DaoStruct>(dao_contract_address);

        assert!(coin::is_account_registered<CoinType>(addr),E_INVALID_COIN_TYPE);
        assert!(length>0,E_NO_PROPOSALS);      
        assert!(dao.next_proposal_id>proposal_id,E_INVALID_PROPOSAL_Id);
        //checks the status
        assert!(proposal.status.Active ,E_PROPOSAL_NOT_STARTED);
        assert!(proposal.voting_start_time<timestamp::now_seconds() && proposal.voting_end_time>timestamp::now_seconds(),E_NOT_CORRECT_TIME_WINDOW);
        //check if the account is registered
        assert!(coin::is_account_registered<CoinType>(addr),E_ADDRESS_NOT_REGISTERED);
        //checks the governance token balance
        let governance_token_balance=coin::balance<CoinType>(addr);
        assert!(governance_token_balance>dao.governance_token.threshhold,E_THRESHOLD_NOT_MET);
        voteProposalInternal(proposal,voteCount,voteType,addr);
    }


    public fun executeProposal<CoinType>(account:&signer,dao_contract_address:address,proposal_id:u64) acquires DaoStruct,AllProposals{
        assert!(exists<DaoStruct>(dao_contract_address),E_DAO_CONTRACT_NOT_EXIST);
        let dao_contract=borrow_global<DaoStruct>(dao_contract_address);
        let addr=signer::address_of(account);
        let proposals=borrow_global<AllProposals>(dao_contract_address);
        let proposal=vector::borrow<Proposal>(& proposals.all_proposals,proposal_id);
        assert!(proposal.voting_end_time<timestamp::now_seconds(),E_NOT_CORRECT_TIME_WINDOW);
        assert!(proposal.status.Active,E_PROPOSAL_NOT_STARTED);
        assert!(dao_contract.admin==addr,E_ONLY_ADMIN);

        // let proposals=borrow_global<AllProposals>(dao_contract_address);
        let length=vector::length(&(proposals.all_proposals));
        assert!(length>0,E_NO_PROPOSALS);
        executeProposalInternal<CoinType>(proposal,&dao_contract.dao_signer_capability);


    }

    //ONLY ADMIN     
    public fun startProposal(account:&signer,dao_contract_address:address,proposal_id:u64) acquires DaoStruct,AllProposals{
        assert!(exists<DaoStruct>(dao_contract_address),E_DAO_CONTRACT_NOT_EXIST);
        let addr=signer::address_of(account);
        let dao=(borrow_global<DaoStruct>(dao_contract_address));
        assert!(addr==dao.admin,E_ONLY_ADMIN);
        let proposals=borrow_global_mut<AllProposals>(dao_contract_address);
        assert!(dao.next_proposal_id>proposal_id,E_INVALID_PROPOSAL_Id);
        let proposal=vector::borrow_mut<Proposal>(&mut proposals.all_proposals,proposal_id);
        assert!(proposal.voting_start_time<timestamp::now_seconds() && proposal.voting_end_time>timestamp::now_seconds(),E_NOT_CORRECT_TIME_WINDOW);
        assert!(proposal.status.NotActive,E_PROPOSAL_ALREADY_STARTED);
        proposal.status.Active=true;

    }

    public fun stopProposal(account:&signer,dao_contract_address:address,proposal_id:u64)acquires DaoStruct,AllProposals{
        assert!(exists<DaoStruct>(dao_contract_address),E_DAO_CONTRACT_NOT_EXIST);
        let addr=signer::address_of(account);
        let dao=borrow_global<DaoStruct>(dao_contract_address);
        assert!(addr==dao.admin,E_ONLY_ADMIN);
        let proposals=borrow_global_mut<AllProposals>(dao_contract_address);
        assert!(dao.next_proposal_id>proposal_id,E_INVALID_PROPOSAL_Id);
        let proposal=vector::borrow_mut<Proposal>(&mut proposals.all_proposals,proposal_id);
        assert!(proposal.voting_start_time<timestamp::now_seconds() && proposal.voting_end_time>timestamp::now_seconds(),E_NOT_CORRECT_TIME_WINDOW);
        assert!(proposal.status.NotActive,E_PROPOSAL_ALREADY_STARTED);
        proposal.status.Active=true;

    }    


    //INTERNAL FUNCTIONS
    fun voteProposalInternal(proposal:&mut Proposal,voteCount:u64,voteType:bool,addr:address){
        if(voteType){
            let isPresent=table::contains(&proposal.stats.add_to_yes_vote,addr);
            
            let prevVoteCount=0;
            if (isPresent) {
                prevVoteCount=*(table::borrow(&proposal.stats.add_to_yes_vote, addr));
                
            };           
            //Add the vote
            proposal.stats.total_yes=proposal.stats.total_yes+voteCount;
            //Add to the table
            if (isPresent) {
                table::upsert(&mut proposal.stats.add_to_yes_vote, addr, prevVoteCount + voteCount);
            } else {
                table::add(&mut proposal.stats.add_to_yes_vote, addr, voteCount);
            }

        }else{
            let isPresent=table::contains(&proposal.stats.add_to_no_vote,addr);
            let prevVoteCount =0;
            if (isPresent) {
                prevVoteCount=*table::borrow(&proposal.stats.add_to_no_vote, addr)
            } else {
                prevVoteCount=0;
            };      
            //Add the vote
            proposal.stats.total_no=proposal.stats.total_no+voteCount;
            //Add to the table
            if (isPresent) {
                table::upsert(&mut proposal.stats.add_to_no_vote, addr, prevVoteCount + voteCount);
            } else {
                table::add(&mut proposal.stats.add_to_no_vote, addr, voteCount);
            }          
        }

    }
    
    fun checkFunctionForCreateProposal(
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
    // name:String,
    // description:String,
    // function_name: String,
    // /// The list of function arguments corresponding to the functions to be executed
    // function_args: PropertyMap,
    // voting_start_time:u64,
    // voting_end_time:u64,
    // proposal_id:u64,
    // status:ProposalStatus,
    // stats:ProposalStats,
    fun executeProposalInternal<CoinType>(proposal:& Proposal,dao_signer_cap:& account::SignerCapability){
        let function_name=proposal.function_name;
        if(function_name==string::utf8(b"transfer_fund")){
            let map=proposal.function_args;
            let res_signer=create_signer_with_capability(dao_signer_cap);
            let des_addr=property_map::read_address(&map,&string::utf8(b"dst"));
            let amt=property_map::read_u64(&map,&string::utf8(b"amount"));
            coin::transfer<CoinType>(&res_signer,des_addr,amt);
        }else{
            // let
        }
    }


}