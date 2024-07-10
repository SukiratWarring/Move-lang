module myAddress::Dao_events{
    use aptos_framework::event;
    use std::string::String;
    use std::account;
    use myAddress::DaoContract::GovernanceToken;
    friend myAddress::DaoContract;
    #[event]
    struct DaoCreatedEvent has drop, store {
        name: String,
        resolve_threshold: u64,
        voting_duration: u64,
        min_required_proposer_voting_power: u64,
        next_proposal_id: u64,
        admin: address,
        dao_contract_address:address,
    }    

    public(friend) fun dao_created_event(
        name: String,
        resolve_threshold: u64,
        voting_duration: u64,
        min_required_proposer_voting_power: u64,
        next_proposal_id: u64,
        admin: address,
        dao_contract_address:address,
    ){
        let event = DaoCreatedEvent{
            name,
            resolve_threshold,
            voting_duration,
            min_required_proposer_voting_power,
            next_proposal_id,
            admin,
            dao_contract_address,
        };
    }
}
