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


///reverseGeocode. Convert a location containing latitude and longitude into a textual address

match (t:Tweet)
where t.latitude<>"null"
with toFloat(t.latitude) as latitude, toFloat(t.longitude) as longitude, t
CALL apoc.spatial.reverseGeocode(latitude, longitude) 
YIELD location
set t.location= location.description

//remove a property

match(u: User)
remove u.ev

//check degree centrality.

//Out-degree (top users who received retweets from the most users)

match (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
return u1.name, count(u2) as outDegree
order by outDegree desc
limit 10

//uses who have the highest number of retweets

match (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
return u1.name, sum(r.numRetweets) as totalRetweets
order by totalRetweets desc
limit 10


//In_degree (top users who tweeted the most users).

match (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
return u2.name, count(u1) as inDegree
order by inDegree desc
limit 10

//use who had the most tweets

match (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
return u2.name, sum(r.numRetweets) as totalTweets
order by totalTweets desc
limit 10

//total degree

match (u1:User)-[r:IS_RETWEETED_BY]-(u2:User)
return u2.name, count(u1) as numUsers
order by numUsers desc
limit 10

match (u1:User)-[r:IS_RETWEETED_BY]-(u2:User)
return u2.name, sum(r.numRetweets) as numRetweets
order by numRetweets desc
limit 10

//page rank

//drop myGraph if exists

CALL gds.graph.drop( "myGraph")

//create a named graph
CALL gds.graph.create.cypher(
    "myGraph", 
    "MATCH (u:User) 
        RETURN id(u) as id", 
    "MATCH (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
        RETURN id(u1) as source, id(u2) as target,  r.numRetweets as weight"
)

//weighted

CALL gds.pageRank.stream(
    "myGraph", {
        relationshipWeightProperty: "weight"
    }
) YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name as user, round(score * 100)/100 as score
ORDER BY score desc


//write pageRank score back to the node

CALL gds.pageRank.write(
    "myGraph", {
        relationshipWeightProperty: "weight",
         writeProperty:"pageRank"
    }
)

//apply page rank to specific location

CALL gds.graph.create.cypher(
    "myGraph_london", 
    "MATCH (u1:User {location: 'London'}) 
        RETURN id(u1) as id", 
    "MATCH (u1:User)-[r:IS_RETWEETED_BY]->(u2:User)
        RETURN id(u1) as source, id(u2) as target,  r.numRetweets as weight",
    {
     validateRelationships: false})

CALL gds.pageRank.stream(
    "myGraph_london", {
        relationshipWeightProperty: "weight"
    }
) YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name as user, round(score * 100)/100 as score
ORDER BY score desc

//ArticleRank:

CALL gds.alpha.articleRank.stream("myGraph", {})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).name as user, score
ORDER BY score DESC

//Eigenvector centrality

CALL gds.alpha.eigenvector.stream("myGraph", {}) 
YIELD nodeId, score as score
RETURN gds.util.asNode(nodeId).name as user, score
ORDER BY score DESC


//store eigenvector back to node

CALL gds.alpha.eigenvector.write("myGraph", {
    writeProperty:"eigenvector"
}) 

//Closeness Centrality

CALL gds.alpha.closeness.stream("myGraph", {}) 
YIELD nodeId, centrality as score
RETURN gds.util.asNode(nodeId).name as user, score
ORDER BY score DESC




// Betweenness centrality

CALL gds.betweenness.stream("myGraph", {})
YIELD nodeId,  score
RETURN gds.util.asNode(nodeId).name as user, score
ORDER BY score DESC

//write the reult back

CALL gds.betweenness.write("myGraph", {
    writeProperty:"betweenness"
})