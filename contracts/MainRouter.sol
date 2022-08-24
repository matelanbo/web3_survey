// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MainRouter is Ownable {
    //    using SafeMathChainlink for uint256;

    struct QuestionsStruct {
        uint256 totalRewards;
        uint256 maxAnswers;
        uint256 numberOfAnswers;
        uint256 deadLine;
        uint8 status;
        uint256 timeCreated;
        address[] whoAnswered;
        address creator;
    }

    struct UserStruct {
        uint32[] questionsAnswered;
        uint32[] questionsCreated;
        uint256 totalRewards;
        bool[] rewardsCounted;
    }

    mapping(uint32 => QuestionsStruct) public question;
    mapping(address => UserStruct) public user;
    address[] public answers;
    uint256[] public questionList;
    uint32 public questionId;
    uint8[] questionStatusList;
    uint256[] questionAnsweredList;
    uint256[] questionMaxAnswersList;
    uint256[] questionRewardsList;
    IERC20 public OTToken;

    constructor(address _ourTokenAddress) public {
        OTToken = IERC20(_ourTokenAddress);
        uint32 questionCount = 0;
    }

    function stake(
        uint256 _totalRewards,
        uint256 _maxAnswers,
        uint256 _deadLine
    ) public payable {
        uint256 minStake = 10000000000000000;
        uint256 minDeadLine = 10;

        require(
            OTToken.balanceOf(msg.sender) > _totalRewards,
            "Insufficient Balance!"
        );
        require(_totalRewards >= minStake, "You need to spend more token!");
        require(_deadLine >= minDeadLine, "Deadline too close!");
        OTToken.transferFrom(msg.sender, address(this), _totalRewards);
        question[questionId].totalRewards = _totalRewards;
        question[questionId].maxAnswers = _maxAnswers;
        question[questionId].deadLine = _deadLine;
        question[questionId].status = 0;
        question[questionId].timeCreated = block.timestamp;
        question[questionId].creator = msg.sender;
        question[questionId].numberOfAnswers = 0;
        user[msg.sender].questionsCreated.push(questionId);
        questionStatusList.push(0);
        questionMaxAnswersList.push(_maxAnswers);
        questionAnsweredList.push(0);
        questionRewardsList.push(_totalRewards);
        questionId += 1;
    }

    function getNumberOfQuestions() public view returns (uint32) {
        return questionId;
    }

    function getQuestionsStatus()
        public
        view
        returns (
            uint8[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (
            questionStatusList,
            questionAnsweredList,
            questionMaxAnswersList,
            questionRewardsList
        );
    }

    function isQuestionAnsweredBy(uint32 _questionId, address _address)
        public
        returns (bool)
    {
        for (uint32 i = 0; i < question[_questionId].whoAnswered.length; i++) {
            if (question[_questionId].whoAnswered[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getMyAnsweredQuestions(address _account)
        public
        view
        returns (uint32[] memory)
    {
        return user[_account].questionsAnswered;
    }

    function getMyCreatedQuestions(address _account)
        public
        view
        returns (uint32[] memory)
    {
        return user[_account].questionsCreated;
    }

    function answer(uint32 _questionId) public {
        require(_questionId < questionId, "Question not found!");
        require(
            question[_questionId].status == 0,
            "Question closed or expired!"
        );
        user[msg.sender].questionsAnswered.push(_questionId);
        user[msg.sender].rewardsCounted.push(false);
        question[_questionId].numberOfAnswers += 1;
        questionAnsweredList[_questionId] = question[_questionId]
            .numberOfAnswers;
        question[_questionId].whoAnswered.push(msg.sender);
        if (
            question[_questionId].numberOfAnswers ==
            question[_questionId].maxAnswers
        ) {
            question[_questionId].status = 1;
            questionStatusList[_questionId] = 1;
            for (uint256 id = 0; id < question[_questionId].maxAnswers; id++) {
                updateMyRewards(question[_questionId].whoAnswered[id]);
            }
        }
    }

    function updateQuestionStatus() public {
        for (uint32 id = 0; id < questionId; id++) {
            if (question[id].status == 0) {
                if (
                    block.timestamp - question[id].timeCreated >
                    question[id].deadLine
                ) {
                    question[id].status = 2;
                    questionStatusList[id] = 2;
                }
            }
        }
    }

    function updateMyRewards(address _account) public {
        for (
            uint32 id = 0;
            id < user[_account].questionsAnswered.length;
            id++
        ) {
            uint32 qId = user[_account].questionsAnswered[id];
            if (user[_account].rewardsCounted[id] == false) {
                if (question[qId].status == 1) {
                    user[_account].totalRewards +=
                        question[qId].totalRewards /
                        question[qId].numberOfAnswers;
                    user[_account].rewardsCounted[id] = true;
                } else if (question[qId].status == 2) {
                    user[_account].rewardsCounted[id] = true;
                }
            }
        }
    }

    function myRewards(address _user) public view returns (uint256) {
        return user[_user].totalRewards;
    }

    function claimRewards() public payable {
        uint256 amount = user[msg.sender].totalRewards;
        require(amount > 0, "No rewards found!");
        OTToken.transfer(msg.sender, amount);
        user[msg.sender].totalRewards = 0;
    }
    //answers arrary needs to be modified after claim
}
