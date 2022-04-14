//Chapter 2 Cypher Query Language

//1. Create some nodes and relationships



//add a new person and relationships




//delete all nodes and relationships
match (n)
detach delete (n)

//use merge. Since nodes are created in another query, we need to first MATCH the nodes of interest



// Update
// add a property Music hobby to Mary




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




//Find the neighbors of the neighbors of Florida.




//Find the neighbors of the neighbors of Florida. Remove direct neighbor.





// Variable length patterns
//2 hops



//2-3 hops



//all hops



//aggregation functions: Count, sum and average
//display number of neighbors of Florida




// Create a list of objects. Display all direct neighbors of Florida




//unwind function. 
