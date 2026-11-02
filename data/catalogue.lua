-- Generated upstream facts are the baseline; reviewed records take precedence.
local catalogue = require('data.generated.moves')
for id, entry in pairs(require('data.reviewed_moves')) do catalogue[id] = entry end
return catalogue
