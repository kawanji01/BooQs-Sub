class TagsController < ApplicationController

  def index
    @tags = ActsAsTaggableOn::Tag.most_used(100).order(created_at: :desc)
    @breadcrumb_hash = { t('articles.articles') => root_path,
                         t('tags.tags') => '' }
  end

  def article_tags

  end

  def articles

  end
end
