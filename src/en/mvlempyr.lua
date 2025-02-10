-- {"id":1339243358,"ver":"1.0.2","libVer":"1.0.2","author":"","repo":"","dep":[]}

--- Identification number of the extension.
--- Should be unique. Should be consistent in all references.
---
--- Required.
---
--- @type int
local id = 1339243358

--- Name of extension to display to the user.
--- Should match index.
---
--- Required.
---
--- @type string
local name = "MVLEMPYR"

--- Base URL of the extension. Used to open web view in Shosetsu.
---
--- Required.
---
--- @type string
local baseURL = "https://www.mvlempyr.com/"

--- URL of the logo.
---
--- Optional, Default is empty.
---
--- @type string
local imageURL = "https://assets.mvlempyr.com/images/asset/LogoMage.webp"
--- ChapterType provided by the extension.
---
--- Optional, Default is STRING. But please do HTML.
---
--- @type ChapterType
local chapterType = ChapterType.HTML

--- Index that pages start with. For example, the first page of search is index 1.
---
--- Optional, Default is 1.
---
--- @type number
local startIndex = 1

--- Shrink the website url down. This is for space saving purposes.
---
--- Required.
---
--- @param url string Full URL to shrink.
--- @param _ int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Shrunk URL.
local function shrinkURL(url, _)
    return url:gsub(".-mvlempyr.com/", "")
end

--- Expand a given URL.
---
--- Required.
---
--- @param url string Shrunk URL to expand.
--- @param _ int Either KEY_CHAPTER_URL or KEY_NOVEL_URL.
--- @return string Full URL.
local function expandURL(url, _)
	return baseURL .. url
end

--- Get a chapter passage based on its chapterURL.
---
--- Required.
---
--- @param chapterURL string The chapters shrunken URL.
--- @return string Strings in lua are byte arrays. If you are not outputting strings/html you can return a binary stream.
local function getPassage(chapterURL)
	local url = expandURL(chapterURL)

	--- Chapter page, extract info from it.
	local document = GETDocument(url)
    local htmlElement = document:selectFirst("#chapter")
    return pageOfElem(htmlElement, true)
end

--- Load info on a novel.
---
--- Required.
---
--- @param novelURL string shrunken novel url.
--- @return NovelInfo
local function parseNovel(novelURL)
	local url = expandURL(novelURL)

	--- Novel page, extract info from it.
	local document = GETDocument(url)
    local desc = ""
    map(document:select(".synopsis p"), function(p)
        desc = desc .. '\n' .. p:text()
    end)
    local img = document:selectFirst("img.novel-image2")
    img = img and img:attr("src") or imageURL
    local nerve_endings = shrinkURL(document:selectFirst(".continuebutton"):attr("href")):match("(.+)%d+$")
    local i = 0
	return NovelInfo({
        title = document:selectFirst(".novel-title2"):text():gsub("\n" ,""),
        imageURL = img,
        description = desc,
        chapters = AsList(
            map(document:select(".chapter-item h3"), function(v)
                i = i + 1
                return NovelChapter {
                    order = i,
                    title = v:text(),
                    link = shrinkURL(nerve_endings .. i)
                }
            end)
        )
    })
end

local listing_page_parm
local function getListing()
    local document = GETDocument(expandURL("novels" .. (listing_page_parm and (listing_page_parm .. data[PAGE]) or "")))
    if not listing_page_parm then
        listing_page_parm = document:selectFirst(".painationbutton.w--current")
        if not listing_page_parm then
            error(document)
        end
        listing_page_parm = listing_page_parm:attr("href")
        if not listing_page_parm then
            error("Failed to find listing href")
        end
        listing_page_parm = listing_page_parm:match("%?[^=]+=")
        if not listing_page_parm then
            error("Failed to find listing match")
        end
    end
    return map(document:select("div.searchlist[role=\"listitem\"]"), function(v)
        return Novel {
            title = v:selectFirst("h2"):text(),
            link = shrinkURL(v:selectFirst("a"):attr("href")),
            imageURL = v:selectFirst("img"):attr("src")
        }
    end)
end

local function search(data)
    local query = data[QUERY]
    local document = GETDocument(expandURL("advance-search"))
    return mapNotNil(document:select("div.searchitem"), function(v)
        local name = v:selectFirst(".novelsearchname"):text()
        if not name:lower():match(query) then
            return nil
        end
        return Novel {
            title = name,
            link = shrinkURL(v:selectFirst("a"):attr("href")),
            imageURL = imageURL
        }
    end)
end

-- Return all properties in a lua table.
return {
	-- Required
	id = id,
	name = name,
	baseURL = baseURL,
	listings = {
        Listing("Default", true, getListing)
    }, -- Must have at least one listing
	getPassage = getPassage,
	parseNovel = parseNovel,
	shrinkURL = shrinkURL,
	expandURL = expandURL,
    hasSearch = true,
    isSearchIncrementing = false,
    hasCloudFlare = true,
    search = search,
	imageURL = imageURL,
	chapterType = chapterType,
	startIndex = startIndex,
}
