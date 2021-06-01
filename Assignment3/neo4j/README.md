# How to migrate to neo4j

1. Export every table to a `.csv` file

```sql
SELECT * FROM XDOCENTES;
SELECT * FROM XDSD;
SELECT * FROM XTIPOSAULA;
SELECT * FROM XOCORRENCIAS;
SELECT * FROM XUCS;
```

![](images/oracle-export-csv.png)

2. Create a new project in Neo4j Desktop, with DMBS and database

![](images/neo4j-project.png)

3. Click the `Reveal files in File Explorer`, which will open a file browser window. Move the `.csv` files in the `data` folder and copy the `create.cypher` file to this folder.

4. Click the `Open` button on the `create.cypher` file, then press the start icon button.