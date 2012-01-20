### Sync Zotero pdfs to Kindle

# Folders to look for pdfs in
zot.fold=list.dirs(path = "C:/Users/Hayley/AppData/Roaming/Zotero/Zotero/Profiles/14iqeur3.default/zotero/storage", full.names=T)

# Zotero pdfs (full directory)
zot.pdf=list.files(path = zot.fold, full.names = TRUE)
zot.pdf=zot.pdf[grepl(".*pdf$", zot.pdf)==T]
# Names only
zot.pdf.names=sub("^.*/","",zot.pdf, perl=T)
# Kindle pdfs
kindle.pdf=list.files(path="E:/documents")
# Copy only files which are not already on kindle
files.to.copy=zot.pdf[zot.pdf.names %in% kindle.pdf==F]

# Copy files onto Kindle
file.copy(as.character(files.to.copy),"E:/documents")


###### Organization (attempt) #######
library(RSQLite)

#Zotero Collections
z.sql=dbConnect("SQLite","C:/Users/Hayley/AppData/Roaming/Zotero/Zotero/Profiles/14iqeur3.default/zotero/zotero.sqlite")
dbListTables(z.sql)

dbReadTable(z.sql,"collections")
head(dbReadTable(z.sql,"collectionItems"))
(dbReadTable(z.sql,"itemAttachments"))

z.query=dbGetQuery(z.sql, "SELECT collectionName, path FROM collections, collectionItems, itemAttachments WHERE collections.collectionID = collectionItems.collectionID AND collectionItems.itemID = itemAttachments.sourceItemID") 

z.query1=z.query[grepl(".*pdf$", z.query$path)==T,]
z.query1$path=sub("storage:", "",z.query1$path,perl=T)
z.query1= z.query1[z.query1$path %in% zot.pdf.names==T,]

## Creating Kindle folders
library(rjson)

#Read in Kindle JSON file
k.json=("E:/system/collections.json")


