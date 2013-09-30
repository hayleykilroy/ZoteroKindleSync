### Sync PDFs in Zotero Collections to Kindle ###

#######################################
# tested on Kindle DX, but should also work on other e-reader Kindle models, except for Kindle 1 and Touch (eg does not work on Fire tablets)
# if your Zotero storage is in your Firefox profile folder, you need to close Firefox before running this script
# after running the script, you need to hard-reset your Kindle by holding the power switch for 20 seconds to reload collections.json
#######################################

#######################################
## modify to approriate values before running
#######################################
zot.path = "C:/.../zotero/"
kindle.path = "D:/"
kindle.lang = "@en-us"
#######################################

library(RSQLite)
library(digest)
library(RJSONIO) # one way to get this package: install.packages("RJSONIO", repos = "http://www.omegahat.org/R", type="source")

# get PDFs in Zotero and on Kindle, and copy Zotero files not already on kindle
zot.pdf = grep(".*pdf$", list.files(path = list.dirs(path=paste(zot.path,"storage",sep=""),full.names = TRUE), full.names = TRUE), value = TRUE)
kindle.pdf = list.files(path=paste(kindle.path,"documents",sep=""))
files.to.copy = zot.pdf[basename(zot.pdf) %in% kindle.pdf==F]
file.copy(as.character(files.to.copy),paste(kindle.path,"documents",sep=""))

# get PDFs sorted by Zotero collection
z.sql = dbConnect("SQLite",paste(zot.path,"zotero.sqlite",sep=""))
z.query = dbGetQuery(z.sql,"SELECT collectionName, path FROM collections, collectionItems, itemAttachments WHERE collections.collectionID = collectionItems.collectionID AND collectionItems.itemID = itemAttachments.sourceItemID")
z.query.pdfs = z.query[grepl(".*pdf$", z.query$path)==T,]
z.query.pdfs$path = sub("storage:", "",z.query.pdfs$path,perl=T)
z.query.pdfs = z.query.pdfs[z.query.pdfs$path %in% basename(zot.pdf)==T,]

# get Zotero collection names
z.collections = sort(unique(unlist(z.query.pdfs$collectionName, use.names = FALSE)))

# format and store hashed Zotero PDF filepaths for Kindle
# hashes have the format: digest("/mnt/us/documents/filename.pdf",algo="sha1",serialize=FALSE) with a * character prefix
z.hashed = list()
for (collection in z.collections) {
	coll = z.query.pdfs[z.query.pdfs$collectionName == collection,]
	toDigest = paste("/mnt/us/documents/",coll$path,sep="")
	coll[["hash"]] = paste("*",sapply(toDigest,digest,algo="sha1",serialize=FALSE,USE.NAMES=FALSE),sep="")
	z.hashed = rbind(z.hashed,coll)
}

# create Kindle collections that correspond to Zotero collections
k.json = fromJSON(paste(kindle.path,"system/collections.json",sep=""))

# to do: just rebuild the collections file on each run since it takes so little time to create
# k.json = fromJSON(json_str = "{}")

for (collection in z.collections) {
	coll.hashes = k.json[[collection]]$items
	
	k.coll = paste(collection,kindle.lang,sep="")
	
	# if a zotero hash isn't listed in the kindle collection, add it
	for (zhash in z.hashed[z.hashed$collectionName == collection,]$hash) {
		if (zhash %in% k.json[[k.coll]]$items == F)
			k.json[[k.coll]]$items = c(k.json[[k.coll]]$items,zhash)
	}
		
	# if a kindle hash isn't listed in the zotero collection, delete it
	for (khash in k.json[[k.coll]]$items) {
		if (khash %in% z.hashed[z.hashed$collectionName == collection,]$hash == F)
			k.json[[k.coll]]$items = k.json[[k.coll]]$items[k.json[[k.coll]] != khash]
	}
	
	# set the last accessed time to alphabetize
	k.json[[k.coll]]$lastAccess = length(z.collections) - which(z.collections == collection)
}

k.json = toJSON(k.json)
write(k.json,paste(kindle.path,"system/collections.json",sep=""))
