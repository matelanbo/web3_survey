from brownie import accounts, config, MainRouter
import yaml
import json
import os
import shutil

OTTokenAddress = "0x0c62C82b0c554992F9f20EC2d552f7Dd5c5192A2"


def deploy_main_router(front_end_update=False):
    account = accounts.add(config["wallets"]["from_key"])
    # account = accounts[0]
    main_router = MainRouter.deploy(OTTokenAddress, {"from": account})
    print("contract deployed to", main_router.address)
    # add_allowed_tokens(main_router, OTTokenAddress, account)
    #   transaction = main_router.stake(
    #       10000000000000000, OTTokenAddress, {"from": account, "value": 50000000000000000}
    #   )
    #   transaction.wait(1)
    # answer = main_router.answer()
    #    main_router.answer()
    # rewards = main_router.myRewards(account)
    # print("my rewards is:", rewards)
    #    transaction = main_router.claimRewards({"from": account})
    #    transaction.wait(1)
    if front_end_update:
        update_front_end()


# def add_allowed_tokens(main_router, allowed_token, account):
#    add_tx = main_router.addAllowedTokens(allowed_token, {"from": account})
#    add_tx.wait(1)
#    pass


def update_front_end():
    # Send the build folder
    copy_folders_to_front_end("./build", "./front_end/src/chain-info")

    # Sending the front end our config in JSON format
    with open("brownie-config.yaml", "r") as brownie_config:
        config_dict = yaml.load(brownie_config, Loader=yaml.FullLoader)
        with open("./front_end/src/brownie-config.json", "w") as brownie_config_json:
            json.dump(config_dict, brownie_config_json)
    print("Front end updated!")


def copy_folders_to_front_end(src, dest):
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.copytree(src, dest)


#  rewards = main_router.myRewards()
#  print(rewards)


def main():
    deploy_main_router(front_end_update=True)
