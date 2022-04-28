/* Preparation steps:

1. Create a new project (Climate Change Tweet Graph), use version 4.1.3
2. copy all files into the import folder of this project
3. make sure you install proper APOC and GDS Library
4. go to the setting, change maxt heap size to 5G: dbms.memory.heap.max_size=5G
5. go to the setting, set apoc.import.file.enabled=true

//check below link for use neo4j bulk import
https://neo4j.com/docs/operations-manual/current/tools/neo4j-admin-import/

really important: do not put extra space in import script or header file
*/

//go to neo4j terminal shell, execute the following command to import climate change tweets data. 

bin\neo4j-admin import --database=neo4j --delimiter="," --skip-bad-relationships=true --ignore-empty-strings=true --nodes import/user_node_header.csv,import/user_node.csv --nodes import/tweet_node_header.csv,import/tweet_node.csv --relationships import/retweet_edge_header.csv,import/retweet_edge.csv --relationships import/tweeted_edge_header.csv,import/tweeted_edge.csv


// add outDegree to user node

match (u1:User)-[:IS_RETWEETED_BY]->(u2:User)
with u1, u1.name as name, count(u2) as outDegree
set u1.outDegree=outDegree


//add inDegree to user Node

match (u1:User)-[:IS_RETWEETED_BY]->(u2:User)
with u2, u2.name as name, count(u1) as inDegree
set u2.inDegree=inDegree

//add total degree to user node

match (u1:User)-[:IS_RETWEETED_BY]-(u2:User)
with  u1, u1.name as name, count(u2) as totalDegree
set u1.totalDegree=totalDegree


THIS EXERCISE ASSUME YOU HAVE RUN COMMUNITY DETECTION TO ADD communityID based on label propagation and Louvain to user node

// find top 5 community based on label propagation

match (u:User)
return u.lp, count(u) as numUsers
order by numUsers desc
limit 5

//result

u.lp,numUsers
392710,880
45435,427
6781,374
16923,372
56784,230

//create a graph based on top 5 community to be used in Gephi

match (u1:User)-[r:IS_RETWEETED_BY]-(u2)
where u1.lp in [392710, 45435, 6781, 16923, 56784] and u2.lp in [392710, 45435, 6781, 16923, 56784]
return u1.name as source, u2.name as target, r.numRetweets as weight, u1.lp as lp_id
order by weight desc


//Find top 5 community based on the Louvain algorithm


//display top 10 users based on modularity

match (u:User)
return u.modularity, count(u) as numUsers
order by numUsers desc
limit 10

//result

u.modularity,numUsers
148911,4702
70233,2551
214516,2129
61508,526
273557,321

//create a graph based on top 5 community to be used in Gephi

match (u1:User)-[r:IS_RETWEETED_BY]-(u2)
where u1.modularity in [58327, 214516, 30912,60732,214662] and u2.modularity in [58327, 214516, 30912,60732,214662]
return u1.name as source, u2.name as target, r.numRetweets as weight, u1.modularity as modularity
order by weight desc


//extrac user data in the same community (based on label propagation)

match (u:User {lp:392710})-[:TWEETED]-(t:Tweet)
return u.name, u.favorites, u.friends, u.followers, u.location, u.joining_year,u.pageRank, u.outDegree, t.created_at, t.source, t.text, t.tweet_id
