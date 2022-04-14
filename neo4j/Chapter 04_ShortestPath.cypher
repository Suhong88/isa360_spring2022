Use Graph DBMS 4.2.1, Graph Data Science Library 1.4.1

//Chapter 4 Shortest Path

Show databases;
create database chapter4
Drop database chapter4


//Using the shortest path algorithm within Neo4j

CREATE (A:Node {name: "A"})
CREATE (B:Node {name: "B"})
CREATE (C:Node {name: "C"})
CREATE (D:Node {name: "D"})
CREATE (E:Node {name: "E"})

CREATE (A)-[:LINKED_TO {weight: 10}]->(B)
CREATE (A)-[:LINKED_TO {weight: 33}]->(C)
CREATE (A)-[:LINKED_TO {weight: 35}]->(D)
CREATE (B)-[:LINKED_TO {weight: 20}]->(C)
CREATE (C)-[:LINKED_TO {weight: 28}]->(D)
CREATE (C)-[:LINKED_TO {weight: 6 }]->(E)
CREATE (D)-[:LINKED_TO {weight: 40}]->(E)

//create a named graph

CALL gds.graph.create("mygraph", "Node", "LINKED_TO")

//Find the shortest path between node A and node E (unweighted)

MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL gds.alpha.shortestPath.stream("myGraph", {startNode: A, endNode: E})
YIELD nodeId, cost
RETURN gds.util.asNode(nodeId).name as name, cost

//note: It is important to note that Dijkstra's algorithm only returns one shortest path. If several solutions exist, only one will be returned

//Find the shortest path between node A and node E (weighted)

//need to create another named graph that includes weight property

CALL gds.graph.create("mygraph_weighted", "Node", "LINKED_TO",  {
        relationshipProperties: [{weight: 'weight' }]
    }
)

MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL gds.alpha.shortestPath.stream("mygraph_weighted", {
        startNode: A, 
        endNode: E,
        relationshipWeightProperty: "weight"
    }
)
YIELD nodeId, cost
RETURN gds.util.asNode(nodeId).name as name, cost

//path visualization
//writes the result of the shortest path algorithm into an sssp property on the nodes belonging to the shortest path.

MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL gds.alpha.shortestPath.write("mygraph_weighted", {
        startNode: A, 
        endNode: E,
        relationshipWeightProperty: "weight"
    }
) YIELD totalCost 
RETURN totalCost

//visualize the shortest path

MATCH (n:Node)
WHERE n.sssp IS NOT NULL
WITH n
ORDER BY n.sssp
WITH collect(n) as path
UNWIND range(0, size(path)-1) AS index
WITH path[index] AS currentNode, path[index+1] AS nextNode
MATCH (currentNode)-[r:LINKED_TO]-(nextNode)
RETURN currentNode, r, nextNode


//K-shortest path
//Dijkstra's algorithm and the A* algorithm only return one possible shortest path between two nodes. 
//If you are interested in the second shortest path, you will have to go for the k-shortest path or Yen's algorithm

MATCH (A:Node {name: "A"})
MATCH (E:Node {name: "E"})
CALL gds.alpha.kShortestPaths.stream("mygraph_weighted", {
            startNode: A, 
            endNode: E, 
            k:2, 
            relationshipWeightProperty: "weight"}
)
YIELD index, sourceNodeId, targetNodeId, nodeIds
RETURN index, 
       gds.util.asNode(sourceNodeId).name as source, 
       gds.util.asNode(targetNodeId).name as target, 
       gds.util.asNodes(nodeIds) as path 
       
//Single Source Shortest Path (SSSP)
//find the shortest path between a given node and all other nodes in the graph

MATCH (A:Node {name: "A"})
CALL gds.alpha.shortestPath.deltaStepping.stream("mygraph_weighted", {
        startNode: A, 
        relationshipWeightProperty: "weight", 
        delta: 1
    }
)
YIELD nodeId, distance
RETURN gds.util.asNode(nodeId).name, distance

//All-pairs shortest path
// It returns the shortest path between each pair of nodes in the projected graph.

CALL gds.alpha.allShortestPaths.stream("mygraph_weighted", {
 relationshipWeightProperty: "weight"
})IELD sourceNodeId, targetNodeId, distance
where sourceNodeId<>targetNodeId
RETURN gds.util.asNode(sourceNodeId).name as start,
 gds.util.asNode(targetNodeId).name as end,
 distance

//Finding the minimum spanning tree in a Neo4j graph

MATCH (A:Node {name: "A"})
CALL gds.alpha.spanningTree.minimum.write("mygraph_weighted", {
    startNodeId: id(A),
    relationshipWeightProperty: 'weight',
    writeProperty: 'MINST',
    weightWriteProperty: 'writeCost'
})
YIELD createMillis, computeMillis, writeMillis, effectiveNodeCount
RETURN *

MATCH (n)-[r:MINST]-(m)
RETURN n, r, m