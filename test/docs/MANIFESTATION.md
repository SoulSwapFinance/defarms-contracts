# **Manifestation Tests**

## **CONSTANTS**

### Booleans
- [ .. ] **isNativePair**
    - [ .. ] initialized?
    - [ .. ] immutable?
- [ .. ] **isManifested**
    - [ .. ] initialized?
    - [ .. ] immutable?
- [ .. ] **isSetup**
    - [ .. ] initialized?
    - [ .. ] immutable?

### **Numeric**
- [ .. ] **startTime**
    - [ .. ] initializable?
    - [ .. ] immutable?
- [ .. ] **endTime**
    - [ .. ] initializable?
    - [ .. ] immutable?
- [ .. ] **duraDays**
    - [ .. ] initializable?
    - [ .. ] immutable?

### **Addresses // Tokens**
- [ .√. ] **usdcAddress**
- [ .√. ] **wnativeAddress**
- [ .√. ] **rewardAddress**
    - [ .√. ] **rewardToken**
- [ .∫. ] **depositAddress**
    - [ .∫. ] **depositToken**
- [ .√. ] **creatorAddress**
- [ .√. ] **manifester**

### **Strings**
- [ .√. ] **name**
- [ .√. ] **symbol**
- [ .. ] **nativeSymbol**
    - [ .. ] meaningful?

## **VARIABLES**

### **Numeric**
- [ .. ] **lastRewardTime**
- [ .. ] **accRewardPerShare**
- [ .√. ] **dailyReward**
- [ .. ] **totalRewards**
- [ .. ] **rewardPerSecond**
- [ .√. ] **feeDays**

### **Strings**
- [ .√. ] **logoURI**
    - [ .√. ] **setLogoURI**
        - [ .√. ] **check**: restricted access (onlyDAO)
        - [ .√. ] **check**: logoURI update
### **Booleans**
- [ .√. ] **isSettable**
    - [ .√. ] **toggleSettable(true)**
        - [insert disabled functions here...]
    - [ .√. ] **toggleSettable(false)**
        - [insert enabled functions here...]
- [ .. ] **isEmergency**
    - [ .. ] **toggleEmergency(true)**
        - [insert disabled functions here...]
    - [ .. ] **toggleEmergency(false)**
        - [insert enabled functions here...]
- [ .. ] **isActivated**
    - [ .. ] **toggleActive(true)**
        - [insert disabled functions here...]
    - [ .. ] **toggleActive(false)**
        - [insert enabled functions here...]

### **Addresses**
- [ .√. ] **DAO**
    - [ .√. ] **setDAO()**
        - [ .√. ] verify update
- [ .√. ] **soulDAO**
    - [ .√. ] **setSoulDAO()**
        - [ .√. ] verify update

## **Modifiers**

## **Access Control**

## **Getters**

## **Deposits**

## **Withdrawals**
