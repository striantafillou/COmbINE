function constraint = discriminatingConstraint(a, b, g, colliderPath, iPag, collider, variables)
%Returns constraint: discriminating(path)->(not) collider(a, b, g)
nnendpoints = length(colliderPath)-2;
from = colliderPath(1:end-1); to = colliderPath(2:end);
toBeInducing = variables.inducing...
    (sub2ind(size(variables.ancestral), to, from, iPag*ones(1, nnendpoints+1)));
toBeAncestral = variables.ancestral...
    (sub2ind(size(variables.ancestral), colliderPath(2:end-1), b*ones(1, nnendpoints), iPag*ones(1, nnendpoints)));
toBeNonAncestral = variables.ancestral...
    (sub2ind(size(variables.ancestral), [from to],[to from], iPag*ones(1, 2*(nnendpoints+1))));
discpathConstraint = [-variables.inducing(colliderPath(1), g, iPag) toBeInducing toBeAncestral -toBeNonAncestral];

if collider
    constraint = [discpathConstraint -variables.ancestral(b, a, iPag) 0;...
        discpathConstraint -variables.ancestral(b, g, iPag) 0];
else
    constraint = [discpathConstraint variables.ancestral(b, a, iPag) variables.ancestral(b, g, iPag) 0];
end

end