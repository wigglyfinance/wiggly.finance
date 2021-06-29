pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract WigglyFinance is ERC20, ERC20Detailed {

    struct Invester {
        uint256 _joined;
        uint256 _amount;
        uint256 _rewards;
        address _referrer;
    }
    
    uint256 private _minimum = 1000000; // minimum transaction fee = 1000000
    
    uint256 private _minutesElapse = 1051200; //60*24*365*2; // 2 Year.
    
    uint256 private _tokenRate = 6; // 1 wiggly for 6 tron.
    
    uint256 public initialsupply = 40000000; // Total Supply.
    
    uint256 private _initialwillbeSold = 4000000; // Total Sale Wiggly
    
    uint256 private _payofowner = 2000000;
    
    uint256 private _ticketprice = 10;
    
    uint256 private _totalLottaryReward = 20000; // Total Lottary Reward;
    
    uint256 private referralRate = 10; // 10% reference income.
    
    uint256 private resetMaxInvestmenttRate = 10; // burn 10% for reset max investment.
    
    uint256 private _fee = 2000000; // 2 TRX.
    
    uint8 private _decimal = 6;
    
    uint256 private _totalOnSale;
    
    uint256 public totalReward;
    
    uint256 public waitingTimer = 0; // Waiting Timer;
    
    address payable private _owner;
    
    address[] internal investmentholders;
    
    address[] internal referrerholders;
    
    mapping(address => Invester) private _investers;
    
    mapping(uint256 => address) public luckyInvesters;
    
    mapping(address => uint256) public referrer;
    
    mapping(address => uint256) private withdrawals;
    
    mapping(address => uint256) public maxinvestment;
    
    mapping(address => uint256) private tickets;
    
    mapping(address => uint256) private ticketnumbers;
    
    event CreateInvesment(address investor, uint256 amount);
    
    event Withdraw(address investor, uint256 amount);
    
    modifier onlyOwner {
      require(msg.sender == _owner, "ONLY THE CONTRACT OWNER CAN USE IT.");
      _;
    }
    
    modifier permission {
        require(waitingTimer != 0, "ICO IS NOT FINISHED YET");
        require(waitingTimer <= block.timestamp, "INVESTMENT HAS NOT STARTED YET");
      _;
    }
    
    /**
     * @dev See Withdraw
     * 
     * Shows the earnings of the investor.
     */
    
    function getWithdrawals(address _account) public view returns (uint256) {
        return withdrawals[_account];
    }
    
    /**
     * @dev See _totalOnSale
     * 
     * Displays the total number of Wiggly available for sale
     * 
     */
    
    function totalOnSale() public view returns (uint256) {
        return _totalOnSale;
    }
    
    /**
     * @dev See Owner
     * 
     * Shows the contract holder's address
     * 
     */
     
    function Owner() public view returns (address) {
        return _owner;
    }
    
    /**
     * @dev See Invester control.
     * 
     */
     
    function _isInvestmentholder(address _invester) public view returns(bool, uint256) {
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            if (_invester == investmentholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    /**
     * @dev Reference control. 
     * 
     */
    
    function _isReferrerholder(address _referrer) public view returns(bool, uint256) {
        for (uint256 s = 0; s < referrerholders.length; s += 1){
            if (_referrer == referrerholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    /**
     * @dev Add invester to holder. 
     * 
     */
    
    function _addInvestmentholder(address _invester) private {
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(_invester);
        if(!blnIsInvestmentholder) investmentholders.push(_invester);
    }
    
    /**
     * @dev Add Referrer to holder. 
     * 
     */
     
    function _addReferrerholder(address _referrer) private {
        (bool blnIsReferrerholder, ) = _isReferrerholder(_referrer);
        if(!blnIsReferrerholder) referrerholders.push(_referrer);
    }
    
    /**
     * @dev Get Investers investment amount. 
     * 
     */
     
    function getInvestment(address _invester) public view returns (uint256) {
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(_invester);
        if(blnIsInvestmentholder) {
            return _investers[_invester]._amount;
        }
        return 0;
    }
    
    /**
     * @dev Total number of users the user refers.
     * 
     */
    
    function getReferralInvestors(address _account) public view returns(uint256){
        uint256 _referrals = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            if(_investers[investmentholders[s]]._referrer == _account){
                _referrals = _referrals.add(1);
            }
        }
        return _referrals;
    }
    
    /**
     * @dev Total investment amount.
     * 
     */
    
    function totalInvestment() public view returns(uint256) {
        uint256 _totalInvestment = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            _totalInvestment = _totalInvestment.add(_investers[investmentholders[s]]._amount);
            }
        return _totalInvestment;
    }
    
    function hasReference(address _invester) public view returns(bool) {
        if(_investers[_invester]._referrer != address(0x0)){
            return true;
        }
        return false;
    }
    
    function getTicket(address _account) public view returns(uint256){
        return tickets[_account].div(_ticketprice.mul(10 ** uint256(_decimal)));
    }
    
    function getReference(address _account) public view returns(address){
        return _investers[_account]._referrer;
    }
    
    function totalHolder() public view returns(uint256){
        return investmentholders.length;
    }
    
    function totalReferrer() public view returns(uint256){
        return referrerholders.length;
    }
    
    /**
     * name : Wiggly Finance
     * symbol : WGL
     * decimal : 6
     */
    
    /**
     * @dev Сonstructor Sets the original roles of the contract
     */
    
    constructor() public ERC20Detailed("Wiggly Finance", "WGL", _decimal){
        _owner = msg.sender;
        _totalOnSale = _totalOnSale.add(_initialwillbeSold * (10 ** uint256(_decimal)));
        totalReward = initialsupply.sub(_initialwillbeSold).sub(_payofowner).mul((10 ** uint256(_decimal)));
       _mint(msg.sender, (_payofowner * (10 ** uint256(_decimal))));
    }
    
    /**
     * @dev fallback function, redirect from wallet to deposit()
     */
     
    function () external payable {
        deposit(address(0x0));
    }
    
    /**
     * #dev Sends wiggly for tron
     */
     
    function deposit(address _referred) public payable {
    
        uint256 _sold;
        
        if(_totalOnSale >= (2000000 * (10 ** uint256(_decimal)))){
            _sold = msg.value.div(_tokenRate);
        }else if(_totalOnSale <= (1000000 * (10 ** uint256(_decimal)))){
            _sold = msg.value.div(_tokenRate + 2);
        }else{
            _sold = msg.value.div(_tokenRate + 1);
        }
        
        require(msg.value >= _minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(_totalOnSale >= _sold, 'NOT ENOUGH TOKENS TO BE SOLD');

        if(_referred != address(0x0) && _referred != msg.sender && !hasReference(msg.sender)){
            
            uint256 _reward = _sold.mul(referralRate).div(100);
            _addReferrerholder(_referred);
            _investers[msg.sender]._referrer = _referred;
            referrer[_referred] = referrer[_referred].add(_reward);
            
        }
        
        _mint(msg.sender,_sold);
        _totalOnSale = _totalOnSale.sub(_sold);
        _owner.transfer(msg.value);
        
    }
    
    
    function resetMaxDeposit() public payable{
        
        require(maxinvestment[msg.sender] > 0, 'INVESTMENT MUST BE GREATER THAN ZERO');
        uint256 _burnFee = maxinvestment[msg.sender].mul(10).div(100); // %10 BURN
        require(balanceOf(msg.sender) >= _burnFee, "YOUR BALANCE IS INSUFFICIENT"); 
        require(msg.value == 5000000, 'VALUE MUST BE EQUAL TO MAX INFESTMENT FEE');
        require(address(this).balance >= 5000000, "YOUR BALANCE IS INSUFFICIENT");
        
        maxinvestment[msg.sender] = 0; // Reset Max Investment
        _burn(msg.sender,_burnFee);
        _owner.transfer(msg.value);
        
    }
    
    function createInvesment(uint256 _amount, address _referred) permission external{

        require(balanceOf(msg.sender) >= _amount, "YOUR BALANCE IS INSUFFICIENT");
        require(_amount >= _minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');
        
        if(_referred != address(0x0) && _referred != msg.sender && !hasReference(msg.sender)){
            _addReferrerholder(_referred);
            _investers[msg.sender]._referrer = _referred;
        }
        
        if(_investers[msg.sender]._amount.add(_amount) > maxinvestment[msg.sender]){
            uint256 _difference = _investers[msg.sender]._amount.add(_amount).sub(maxinvestment[msg.sender]);
            maxinvestment[msg.sender] = maxinvestment[msg.sender].add(_difference);
            tickets[msg.sender] = tickets[msg.sender].add(_difference);
        }
        
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(msg.sender);
        if(blnIsInvestmentholder){
            uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
            _investers[msg.sender]._rewards = _balance;
            if(hasReference(msg.sender)){
                referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
            }
        }
        
        _investers[msg.sender]._amount = _investers[msg.sender]._amount.add(_amount);
        _investers[msg.sender]._joined = block.timestamp;
        _burn(msg.sender,_amount);
        _addInvestmentholder(msg.sender);
        
        emit CreateInvesment(msg.sender, _amount);
    }
    
    function removeInvestment(uint256 _amount) payable external {
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(msg.sender);
        require(blnIsInvestmentholder, 'YOU DO NOT HAVE ANY INVESTMENT');
        require(_investers[msg.sender]._amount > _amount, 'YOUR INVESTMENT IS INSUFFICIENT, TRY `killInvestment()` FUNCTION');
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
        _investers[msg.sender]._rewards = _balance;
        if(hasReference(msg.sender)){
            referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
        }
        
        _investers[msg.sender]._amount = _investers[msg.sender]._amount.sub(_amount);
        _investers[msg.sender]._joined = block.timestamp;
        _mint(msg.sender, _amount);
        _owner.transfer(msg.value);
        
    }
    

    function killInvestment() payable external{
        (bool _isInvestment, uint256 s) = _isInvestmentholder(msg.sender);

        require(_isInvestment, 'YOU DO NOT HAVE ANY INVESTMENT');
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
        
        if(_balance > 0){
            
            if(hasReference(msg.sender)){
                referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
            }
            
            totalReward = totalReward.sub(_balance);
                
            withdrawals[msg.sender] = withdrawals[msg.sender].add(_balance);
            
            _investers[msg.sender]._rewards = 0;
            _investers[msg.sender]._joined = block.timestamp;
            
            emit Withdraw(msg.sender, _balance);
        }
        
        _mint(msg.sender,_investers[msg.sender]._amount.add(_balance));
        _owner.transfer(msg.value);
        _investers[msg.sender]._amount = 0;
        
        
        if(_isInvestment){
            investmentholders[s] = investmentholders[investmentholders.length - 1];
            investmentholders.pop();
        }
    }
    
    function getRate() public view returns (uint256){
        return totalReward.sub(unClaimedRewards()).div(totalInvestment().add(1000000000000).div(10000));
    }
    
    function getReward(address _account) public view returns(uint256){
        if(_investers[_account]._amount > 0){
            return _calculateReward(_account).add(_investers[_account]._rewards);
        }else{
            return 0;
        }
    }
    
    function refReward(address _account) public view returns(uint256){
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            if(_investers[investmentholders[s]]._referrer == _account){
                _totalRewards = _totalRewards.add(_calculateReward(investmentholders[s]).mul(referralRate).div(100));
            }
        }
        return _totalRewards.add(referrer[_account]);
    }
    
    function _calculateReward(address _account) internal view returns(uint256){
        uint256 minutesCount = block.timestamp.sub(_investers[_account]._joined).div(1 minutes); // Time elapsed since the investment was made
        uint256 percent = _investers[_account]._amount.mul(getRate()).div(10000); // how much return
        return percent.mul(minutesCount).div(_minutesElapse); // minute jump, for example 1 day;
    }
    
    function distributeRewards() external onlyOwner returns(bool){

        for (uint256 s = 0; s < investmentholders.length; s += 1){
            uint256 _balance = _calculateReward(investmentholders[s]);
            _investers[investmentholders[s]]._rewards = _investers[investmentholders[s]]._rewards.add(_balance);
            if(hasReference(investmentholders[s])){
                referrer[_investers[investmentholders[s]]._referrer] = referrer[_investers[investmentholders[s]]._referrer].add(_balance.mul(referralRate).div(100));
            }
            _investers[investmentholders[s]]._joined = block.timestamp;
        }
        return true;
    }
    
    function unClaimedRewards() public view returns(uint256) {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            _totalRewards = _totalRewards.add(_investers[investmentholders[s]]._rewards);
        }
        return _totalRewards.add(unClaimedReferrerRewards());
    }
    
    function unClaimedReferrerRewards() public view returns(uint256) {
        uint256 _totalReward = 0;
        for (uint256 s = 0; s < referrerholders.length; s += 1){
            _totalReward = _totalReward.add(referrer[referrerholders[s]]);
            }
        return _totalReward;
    }
    
    function claimReward() public payable returns (bool){
        
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        if(_investers[msg.sender]._amount > 0){
            uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
            if(_balance > 0){
                
                if(hasReference(msg.sender)){
                    referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
                }
                
                totalReward = totalReward.sub(_balance.add(_balance));
                
                withdrawals[msg.sender] = withdrawals[msg.sender].add(_balance);
                _investers[msg.sender]._rewards = 0;
                _investers[msg.sender]._joined = block.timestamp;
                _mint(msg.sender, _balance);
                _owner.transfer(_fee);
                emit Withdraw(msg.sender, _balance);
            }
            return (true);
        }else{
            return (false);
        }
    }
    
    function claimRefererIncome() public payable returns(bool){

        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
            
        (bool blnIsReferrerholder, ) = _isReferrerholder(msg.sender);
        
        if(blnIsReferrerholder){
            totalReward = totalReward.sub(referrer[msg.sender]);
            withdrawals[msg.sender] = withdrawals[msg.sender].add(referrer[msg.sender]);
            _mint(msg.sender,referrer[msg.sender]);
            _owner.transfer(_fee);
             emit Withdraw(msg.sender, referrer[msg.sender]);
            referrer[msg.sender] = 0;
            return true;
        }else{
            return false;
        }
    }
    
    function random(uint256 _num) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp.add(_num), investmentholders)));
    }
    
    function checkTheLottery() public onlyOwner returns(bool){
        
        require(investmentholders.length > 0, 'THERE IS NOT ANY INVESTMENT');
        
        uint256 _luckyNumber;
        uint256 _numbers = 0;
        uint256 _lottaryReward = _totalLottaryReward * (10 ** uint256(_decimal));
        
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            _numbers = _numbers.add(tickets[investmentholders[s]].div(_ticketprice.mul(10 ** uint256(_decimal)))); // calculate tickets
            ticketnumbers[investmentholders[s]] = _numbers; // set ticket numbers;
            tickets[investmentholders[s]] = _investers[investmentholders[s]]._amount; // reset tickets.
        }
        
        if(_numbers > 0){
            for (uint256 l = 0; l < 5; l += 1){
         
                _luckyNumber = random(l) % _numbers;
                
                // 20000 / 2 = 10000 First Prize
                // 10000 / 2 = 5000 Second Prize
                // 5000 / 2 = 2500 Third Prize
                // 2500 / 2 = 1250 fourth and fifth prize
            
                for (uint256 s = 0; s < investmentholders.length; s += 1){
                    if(_luckyNumber <= ticketnumbers[investmentholders[s]]){
                        if(l != 4) _lottaryReward = _lottaryReward.div(2);
                        luckyInvesters[l] = investmentholders[s];
                        _investers[investmentholders[s]]._rewards = _investers[investmentholders[s]]._rewards.add(_lottaryReward);
                        break;
                    }
                }
            }
        }
        
        totalReward = totalReward.sub(_lottaryReward);
        
        return true;
    }
    
    function buyTicket(uint256 _amount) external payable {
        require(balanceOf(msg.sender) >= _amount, "YOUR BALANCE IS INSUFFICIENT");
        require(_amount >= _minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');
        require(_amount > _ticketprice.mul(10 ** uint256(_decimal)), 'VALUE CANNOT BE LESS THEN THE TICKET PRICE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        tickets[msg.sender] = tickets[msg.sender].add(_amount);
        _burn(msg.sender,_amount);
        _owner.transfer(msg.value);
    }
    
    function doneico() external onlyOwner returns(uint256){

        if(_totalOnSale > 0){
            totalReward = totalReward.add(_totalOnSale);
            _totalOnSale = 0;
        }
        
        waitingTimer = block.timestamp.add(1296000); // 1296000 = 15 Day;
        
        return waitingTimer;
        
    }
    
    function withdrawRemainingReward() external onlyOwner{
        require(getRate() == 0, "RATE IS NOT ZERO");
        _mint(_owner,totalReward);
        totalReward = 0;
    }
    
    function withdrawOwner() external onlyOwner{
        if(address(this).balance >= 0)
        {
            _owner.transfer(address(this).balance);
        }
    }
}
