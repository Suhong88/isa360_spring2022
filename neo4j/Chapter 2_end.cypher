//Chapter 2 Cypher Query Language

//1. Create nodes and relationships

CREATE (p: Person {name: "Mary", City: "Smithfield", age: 23})
CREATE (s: Person {name: "Sue", City: "Smithfield", age: 24})
CREATE (p)-[:IS_FRIEND {length: 10}]->(s)
CREATE (s)-[:IS_FRIEND {length: 10}]->(p)

//add a new person and relationship. This will NOT add the new node to the existing graph.

CREATE (n: Person {name: "Bob"})
CREATE (b)-[:IS_FRIEND]->(s)

//delete all nodes and relationships
match (n)
detach delete (n)

//use merge. Since nodes are created in another query, we need to first MATCH the nodes of interest

MATCH (p: Person {name: "Mary"})
MATCH (s: Person {name: "Sue"})
MERGE (b: Person {name: "Bob"})
MERGE (b)-[:IS_FRIEND]->(s)

// Update
// add a property hobby to Mary

match (p: Person {name: "Mary"})
set p.hobby="Music"
Return p


// import file from local folder. Need to store the files in the import folder of database

//first delete existing nodes and relationships

match (n)
detach delete (n)

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/Suhong88/isa360_spring2022/main/data/usa_state_neighbors_edges.csv"  AS row
fieldterminator ';'
merge(n: State {code: row.code})
merge(m:State {code: row.neighbor_code})
merge(n)-[:SHARE_BORDER_WITH]->(m)

//pattern matching and data retrieval
//Find the direct neighbors of Florida and return their names:

MATCH (a:State {code: "FL"})-[:SHARE_BORDER_WITH]-(n)
RETURN n.code

//Find the neighbors of the neighbors of Florida.

MATCH (a:State {code: "FL"})-[:SHARE_BORDER_WITH]-(neighbor)-[:SHARE_BORDER_WITH]-(neighbor_of_neighbor)
RETURN neighbor_of_neighbor.code

//Find the neighbors of the neighbors of Florida. Remove direct neighbor.

MATCH (a:State {code: "FL"})-[:SHARE_BORDER_WITH]-(neighbor)-[:SHARE_BORDER_WITH]-(neighbor_of_neighbor)
Where NOT (a)-[:SHARE_BORDER_WITH]->(neighbor_of_neighbor)
RETURN neighbor_of_neighbor.code

// Variable length patterns
//2 hops
MATCH (a:State {code: "FL"})-[:SHARE_BORDER_WITH*2]->(neighbor)
RETURN neighbor.code

//2-3 hops

MATCH (a:State {code: "FL"})-[r:SHARE_BORDER_WITH*2..3]->(neighbor)
RETURN (a)-[:SHARE_BORDER_WITH]-(neighbor)

//all hops ( it takes a long time to run)
MATCH (a:State {code: "FL"})-[r:SHARE_BORDER_WITH*]->(neighbor)
RETURN neighbor.code


//aggregation functions: Count, sum and average
//display number of neighbors of Florida

MATCH (a:State {code: "FL"})-[:SHARE_BORDER_WITH]-(neighbor)
RETURN a.code as state_name, count(neighbor) as number_of_neighbors

// Create a list of objects. Display all direct neighbors of Florida

MATCH (a:State {code: "FL"})-[:SHARE_BORDER_WITH]-(n)
RETURN COLLECT(n.code)

//unwind function. 
MATCH (a:State {code: "FL"})-[:SHARE_BORDER_WITH]-(n)
WITH COLLECT(n.code) as codes
UNWIND codes as c
RETURN c