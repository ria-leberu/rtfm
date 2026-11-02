local statuses = require('data.generated.statuses')
for id, label in pairs(require('data.reviewed_statuses')) do statuses[id] = label end
return statuses
