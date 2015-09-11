//recommendation engine, what items are most frequently co-sold?
MATCH path = (item:Item)-[:CONTAINS]-(:Transaction)-[:CONTAINS]-(item2:Item)
WHERE id(item) > id(item2)
WITH item, item2, count(distinct path) as instances
ORDER BY instances DESC
LIMIT 3
RETURN item.name, item2.name, instances;
//
//total sales volume (price) by period descending
MATCH (p:Period)-[:OCCURRED_IN]-(t:Transaction)-[:CONTAINS]-(i:Item)
WITH round(sum(i.price)) as sales, p
ORDER BY sales DESC
LIMIT 10
RETURN sales, p.period as period;
//
//total sales volume (price) by period descending
MATCH (t:Transaction)-[:CONTAINS]-(i:Item)
WITH count(distinct(t)) as itemSales, i
ORDER BY itemSales DESC
LIMIT 5
RETURN i.name as name, itemSales as count;
//
//what items are sold most often
MATCH (t:Transaction)-[:CONTAINS]-(i:Item)
WITH count(distinct(t)) as itemSales, i
ORDER BY itemSales DESC
LIMIT 5
RETURN i.name as name, itemSales as count;
//
//Who closed the largest deal?
MATCH (rep)-[:SOLD]-(txn)
WITH rep, txn
MATCH (txn)-[:CONTAINS]-(itm)
WITH rep, txn, round(sum(itm.price)) as dealSize
ORDER BY dealSize DESC
LIMIT 5
RETURN rep.name as name, txn.transactionID as transaction, dealSize as `deal size`;
//
//Who has sold the most volume?
MATCH (rep)-[:SOLD]-(txn)-[:CONTAINS]-(itm)
WITH rep, round(sum(itm.price)) as volume
ORDER BY volume DESC
LIMIT 5
RETURN rep.name as name, volume;
//
//How much comp did we pay out in Period 52?
MATCH (p:Period {period:52})-[:OCCURRED_IN]-(t:Transaction)-[:CONTAINS]-(i:Item)
WITH sum(i.price) as sales, p
RETURN sales, p.period;
//
//flat downstream comp plan, for all items sold in my downsteam I recieve a flat 1%
//for each item I sell directly, I recieve a flat 10%
MATCH (target:Person)<-[:REPORTS_TO*..]-(downStreamers)
WITH target, downStreamers
MATCH (downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.01) as downComission, target
MATCH (target)-[:SOLD]-(txn)-[:CONTAINS]-(itm)
WITH sum(itm.price*.1) + downComission as totalComp, target.name as salesRep
RETURN salesRep, totalComp
ORDER BY totalComp DESC;
//
//more complex, for direct sales you get 10%, for each level down, you get 1% less.
MATCH (target:Person)<-[r:REPORTS_TO*..]-(downStreamers)
WITH target, downStreamers, count(r) as level
MATCH (downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*((10-level)/100)) as downComission, target
MATCH (target)-[:SOLD]-(txn)-[:CONTAINS]-(itm)
WITH sum(itm.price*.1) + downComission as totalComp, target.name as salesRep
RETURN salesRep, totalComp
ORDER BY totalComp DESC;
//
//what about based on specific kickers and based on levels for selling products?
MATCH (target:Person)<-[r:REPORTS_TO*..]-(downStreamers)
WITH target, downStreamers, count(r) as level
MATCH (downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*(((10-level)/100))+item.kicker) as downComission, target
MATCH (target)-[:SOLD]-(txn)-[:CONTAINS]-(itm)
WITH sum(itm.price*.1) + downComission as totalComp, target.name as salesRep
RETURN salesRep, totalComp
ORDER BY totalComp DESC;
//
//what about the magnificent bastard described in the exposition of this blogpost?
//level 1 comp
MATCH (distributor:Person {level:1})-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.25) as tc1, distributor.name as n1
RETURN tc1, n1;
//level 2 comp
MATCH (success_builder:Person {level:2})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.05) as downStream2, success_builder
MATCH (success_builder)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.25) + downStream2 as tc2, success_builder.name as n2
RETURN tc2, n2;
//level 3 comp
MATCH (senior_mage:Person {level:3})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.05)+sum(item.wholesalePrice*.25) as downStream3, senior_mage
MATCH (senior_mage)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.5) + downStream3 as tc3, senior_mage.name as n3
RETURN tc3, n3;
//level 4 comp
MATCH (transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.01) as globalRoyalty
MATCH (guild_leader:Person {level:4})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.07)+sum(item.wholesalePrice*.3) + globalRoyalty as downStreamGlobal4, guild_leader
MATCH (guild_leader)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.5) + downStreamGlobal4 as tc4, guild_leader.name as n4
RETURN tc4, n4;
//level 5 comp
MATCH (transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.02) as globalRoyalty
MATCH (boss:Person {level:5})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.07)+sum(item.wholesalePrice*.3) + globalRoyalty as downStreamGlobal5, boss
MATCH (boss)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.5) + downStreamGlobal5 as tc5, boss.name as n5
RETURN tc5, n5;
//level 6 comp
MATCH (transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.05) as globalRoyalty
MATCH (big_boss:Person {level:6})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.1)+sum(item.wholesalePrice*.5) + globalRoyalty as downStreamGlobal6, big_boss
MATCH (boss)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.65) + downStreamGlobal6 as tc6, big_boss.name as n6
RETURN tc6, n6;
//
//
//TIME SERIES COMP
//what about the magnificent bastard described in the exposition of this blogpost?
//level 1 comp
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction
MATCH (distributor:Person {level:1})-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.25) as tc1, distributor.name as n1
RETURN tc1, n1;
//level 2 comp
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, p
MATCH (success_builder:Person {level:2})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.05) as downStream2, success_builder, p
MATCH(transaction)-[:OCCURRED_IN]-(p)
WITH transaction, downStream2, success_builder
MATCH (success_builder)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.25) + downStream2 as tc2, success_builder.name as n2
RETURN tc2, n2;
//level 3 comp
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, p
MATCH (senior_mage:Person {level:3})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.05)+sum(item.wholesalePrice*.25) as downStream3, senior_mage, p
MATCH (transaction)-[:OCCURRED_IN]-(p)
WITH transaction, downStream3, senior_mage
MATCH (senior_mage)-[:SOLD]-(transaction)-[:CONTAINS]->(item)
WITH sum(item.price*.5) + downStream3 as tc3, senior_mage.name as n3
RETURN tc3, n3;
//level 4 comp
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, p
MATCH (transaction)-[:CONTAINS]->(item)
WITH sum(item.price*.01) as globalRoyalty, transaction, p
MATCH (guild_leader:Person {level:4})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.07)+sum(item.wholesalePrice*.3) + globalRoyalty as downStreamGlobal4, guild_leader, p
MATCH (transaction)-[:OCCURRED_IN]-(p)
WITH transaction, downStreamGlobal4, guild_leader
MATCH (guild_leader)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.5) + downStreamGlobal4 as tc4, guild_leader.name as n4
RETURN tc4, n4;
//level 5 comp
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, p
MATCH (transaction)-[:CONTAINS]-(item), p
WITH sum(item.price*.02) as globalRoyalty
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, p, globalRoyalty
MATCH (boss:Person {level:5})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.07)+sum(item.wholesalePrice*.3) + globalRoyalty as downStreamGlobal5, boss, p
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, p, downStreamGlobal5
MATCH (boss)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.5) + downStreamGlobal5 as tc5, boss.name as n5
RETURN tc5, n5;
//level 6 comp
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, p
MATCH (transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.05) as globalRoyalty, p
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH globalRoyalty, p, transaction
MATCH (big_boss:Person {level:6})<-[r:REPORTS_TO*..]-(downStreamers)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.1)+sum(item.wholesalePrice*.5) + globalRoyalty as downStreamGlobal6, big_boss, p
MATCH (transaction)-[:OCCURRED_IN]-(p:Period {period:35})
WITH transaction, downStreamGlobal6, big_boss
MATCH (boss)-[:SOLD]-(transaction)-[:CONTAINS]-(item)
WITH sum(item.price*.65) + downStreamGlobal6 as tc6, big_boss.name as n6
RETURN tc6, n6;
