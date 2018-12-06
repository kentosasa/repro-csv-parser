async function main() {
	let urlCheck = RegExp('https://app.repro.io/apps/(.*)/push_notifications').exec(location.href)
	if(RegExp('https://app.repro.io/apps/(.*)/push_notifications').exec(location.href)  == null) {
		let reproId = RegExp('https://app.repro.io/apps/(.*)/.*').exec(location.href)[1]
		alert(`https://app.repro.io/apps/${reproId}/push_notifications で実行してください`)
	}
	
    var campaigns = Array.from(document.querySelectorAll('.push_notifications .list tbody td.main-col a'))
    var resultPromise = campaigns.map(async e => {
    	const mimeType = 'text/csv'
    	const name = `${e.querySelector('.line-action').textContent}.csv`
    	
    	// CSV落としてくる
        const res = await fetch(`${e.getAttribute('href')}.csv`)
        const text = await res.text()
        const bom  = new Uint8Array([0xEF, 0xBB, 0xBF])
		const blob = new Blob([bom, text], {type : mimeType})

		// Download用のリンク作る
		let a = document.createElement('a')
		a.download = name
		a.target   = '_blank'
		a.href = window.URL.createObjectURL(blob)
		
        return a
    })

    return await Promise.all(resultPromise)
}

var result = await main()
result.forEach(csv => { csv.click() })