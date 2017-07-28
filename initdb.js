function logerr(obj) {
	if(obj.ok == 0) {
		print(JSON.stringify(obj))
	}
}

try {
	logerr(db.user.createIndex({"username": 1}, {unique: true}))
}
catch(e) {
	print(e)
}
