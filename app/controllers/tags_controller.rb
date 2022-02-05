class TagsController < ApplicationController

  def index
    @tags = ActsAsTaggableOn::Tag.most_used(100).order(created_at: :desc)
    @breadcrumb_hash = { t('articles.articles') => root_path,
                         t('tags.tags') => '' }
  end

  def article_tags

  end

  def articles
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
    articles = Article.tagged_with(@tag.name)
    @articles_count = articles.size
    @articles = articles.order(created_at: :desc).page(params[:page]).per(10)
    @breadcrumb_hash = { t('home.home') => root_path,
                         t('tags.tags') => tags_path,
                         t('tags.article_list', tag_name: @tag.name) => '' }
  end
end
