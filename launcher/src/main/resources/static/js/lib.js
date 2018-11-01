/* Small utilities functions */
function updateOnlyNewFiles(existingFiles, newFiles, updateFct) {
	//update existing files
	for (let file of existingFiles) {
		let newFile = newFiles.find(f => f.name === file.name && f.path === file.path);

		if (newFile) {
			newFile.processed = true
			if (file.lastModified !== newFile.lastModified) {
				updateFct(file, newFile)
			}

		} else {
			file.delete = true
		}
	}

	//remove file
	existingFiles = existingFiles.filter(f => !f.delete)

	//add new files
	newFiles.filter(f => !f.processed).forEach(f => {
		existingFiles.push(f)
		updateFct(f)
	})

	return existingFiles
}