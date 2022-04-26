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

//convert created_at to date

match (t:Tweet)
return apoc.date.format(apoc.date.parse(t.created_at, 'ms', 'yyyy-MM-dd'), 'ms', 'yyyy-MM-dd')
order by t.created_at

//create an index on tweet_id to speed search performance

CREATE INDEX tweet_id_index FOR (t:Tweet) ON (t.tweet_id)


//create a named graph
CALL gds.graph.create.cypher(
    "myGraph", 
    "MATCH (u:User) 
        RETURN id(u) as id", 
    "MATCH (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
        RETURN id(u1) as source, id(u2) as target,  r.numRetweets as weight"
)

//weakly connected components

call gds.wcc.stream("myGraph")
YIELD nodeId, componentId
return gds.util.asNode(nodeId).name as nodeName, componentId
order by componentId


//Strongly connected components

call gds.alpha.scc.stream("myGraph")
YIELD nodeId, componentId
return gds.util.asNode(nodeId).name as nodeName, componentId
order by componentId


//write the GDS results in the graph

call gds.wcc.write("myGraph", {
    writeProperty:"wcc"
})

call gds.alpha.scc.write("myGraph", {
    writeProperty:"scc"
})

//check number of users in each component

match (u:User)
return u.wcc, count(u) as numUsers
order by numUsers desc


match (u:User)
return u.scc, count(u) as numUsers
order by numUsers desc


// Using the label propagation algorithm from the GDS

call gds.labelPropagation.stream("myGraph", 
{ 
    relationshipWeightProperty: "weight"
})
YIELD nodeId, communityId
return gds.util.asNode(nodeId).name as nodeName, communityId
order by communityId

//write the result back to the node
call gds.labelPropagation.write("myGraph", 
{ 
    relationshipWeightProperty: "weight",
    writeProperty:'lp'
})

//display top 10 community based on label Propagation

match (u:User)
return u.lp, count(u) as numUsers
order by numUsers desc
limit 10

//check top community

match (u:User {lp: 392710})
return u.name, u.location

match (u:User {lp: 392710})
with u.name as name, u.location as location
return location, count(name) as NumberOfUsers
order by NumberOfUsers desc

//create a graph based on certain community using Gephi

match (u1:User)-[r:IS_RETWEETED_BY]-(u2)
where u1.lp=284760 and u2.lp=284760
return u1.name as source, u2.name as target, r.numRetweets as weight
order by weight desc


//The Louvain algorithm

call gds.louvain.stream("myGraph", 
{ 
    relationshipWeightProperty: "weight"
})
YIELD nodeId, communityId
RETURN gds.util.asNode(nodeId).name AS nodeName, communityId
ORDER By communityId;

call gds.louvain.write("myGraph", 
{ 
    relationshipWeightProperty: "weight",
    writeProperty:'modularity'
})

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
275089,284
56441,259
49280,201
2865,177
184769,171


//export top community as a csv

match (u1:User)-[r:IS_RETWEETED_BY]-(u2)
where u1.modularity=148911 and u2.modularity=148911
return u1.name as source, u2.name as target, r.numRetweets as weight
order by weight desc

//Apply page rank to a community

//create a sub-graph based on the same community

CALL gds.graph.create.cypher(
    "myGraph_community", 
    "MATCH (u1:User {modularity: 148911}) 
        RETURN id(u1) as id", 
    "MATCH (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
        RETURN id(u1) as source, id(u2) as target,  r.numRetweets as weight",
    {
     validateRelationships: false})
	 
//identify top 10 user in the community

CALL gds.pageRank.stream(
    "myGraph_community", {
        relationshipWeightProperty: "weight"
    }
) YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name as user, round(score * 100)/100 as score
ORDER BY score desc